fs = Npm.require 'fs'
htmlModule = Npm.require 'html'
juice = Npm.require 'juice'
pathModule = Npm.require 'path'
url = Npm.require 'url'

STARTS_WITH_SPACE = /^\s/
ENDS_WITH_SPACE = /\s$/
ENDS_WITH_NEWLINE = /\n$/
# We capture newline to include it in the split.
NEWLINE_SPLIT = /(\n)/

ToPlainTextVisitor = HTML.Visitor.extend()
ToPlainTextVisitor.def
  visitNull: (nullOrUndefined) ->
    ''

  visitPrimitive: (stringBooleanOrNumber) ->
    String(stringBooleanOrNumber).trim()

  _joinWithSpaces: (parts) ->
    parts = (part for part in parts when part isnt '')

    joinedParts = ''

    for part, i in parts
      if i is 0 or i is parts.length - 1
        joinedParts += part
      else if ENDS_WITH_SPACE.test parts[i - 1] or STARTS_WITH_SPACE.test parts[i + 1]
        joinedParts += part
      else
        joinedParts += ' ' + part

    joinedParts

  visitArray: (array) ->
    @_joinWithSpaces (@visit item for item in array)

  visitComment: (comment) ->
    ''

  visitCharRef: (charRef) ->
    charRef.str

  visitRaw: (raw) ->
    @visit HTMLTools.parseFragment raw.value

  _visitTagChildren: (tag) ->
    @_joinWithSpaces (@visit child for child in tag.children)

  _tagAttributes: (tag) ->
    return {} unless tag.attrs

    attributes = {}
    for key, value of HTML.flattenAttributes tag.attrs
      attributes[key] = @toText value, HTML.TEXTMODE.ATTRIBUTE
    attributes

  _joinLinks: ->
    links = (@_links or []).join '\n'
    @_links = []
    links = "#{links}\n" if links isnt ''
    links

  _optionalNewline: (content) ->
    if ENDS_WITH_NEWLINE.test content
      content
    else
      "#{content}\n"

  visitTag: (tag) ->
    attributes = @_tagAttributes tag

    if tag.tagName in ['ul', 'ol', 'dl']
      currentLiCount = @_liCount
      @_liCount = 0
      content = @_visitTagChildren tag
      @_liCount = currentLiCount
    else
      content = @_visitTagChildren tag

    return '' unless content

    switch tag.tagName
      when 'footer'
        # We add two extra lines before the footer.
        "\n\n#{@_optionalNewline content}#{@_joinLinks()}"
      when 'li'
        @_liCount ?= 0
        @_liCount++

        # We add an extra line between li tags at the same level, but before the first li tag.
        "#{if @_liCount is 1 then '' else '\n'}#{@_optionalNewline content}#{@_joinLinks()}"
      when 'p'
        "#{@_optionalNewline content}"
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        "#{@_optionalNewline content}\n"
      when 'a'
        if 'href' of attributes
          unless attributes['data-plaintext'] is 'nolink'
            # We store all links to output them at the end of major blocks.
            @_links ?= []
            @_links.push url.resolve Meteor.absoluteUrl(), attributes.href

          content
        else
          ''
      else
        content

  toText: (node, textMode) ->
    HTML.toText node, textMode

class ActivityEmailsComponent extends UIComponent
  @register 'ActivityEmailsComponent'

  constructor: (@activities) ->
    super

  instrument: ->
    # TODO

  # Based on django.utils.text.wrap.
  _wrapPlainText: (content, width) ->
    lines = []

    for line in content.split NEWLINE_SPLIT
      maxWidth = Math.min((_.endsWith(line, '\n') and width + 1 or width), width)
      while line.length > maxWidth
        space = line.substr(0, maxWidth + 1).lastIndexOf(' ') + 1
        if space is 0
          space = line.indexOf(' ') + 1
          if space is 0
            lines.push line
            line = ''
            break
        lines.push "#{line.substr(0, space - 1)}\n"
        line = line.substr(space)
        maxWidth = Math.min((_.endsWith(line, '\n') and width + 1 or width), width)

      lines.push line

    lines.join ''

  renderComponentToPlainText: ->
    @_wrapPlainText @_renderComponentTo(new ToPlainTextVisitor()), 68

class ActivityEmailsJob extends Job
  @register()

  @DELAY = 60 * 1000 # ms

  enqueueOptions: (options) ->
    _.defaults super,
      delay: @constructor.DELAY

  shouldSkip: (options) ->
    # Does a job which can run or is running exist which will handle activities for this job's timestamp as well?
    !!JobsWorker.collection.findOne
      'data.fromTimestamp':
        $lte: @data.fromTimestamp
      $or: [
        # If a job processing this timestamp range runs on a worker with imprecise clock, then it might
        # happen that toTimestamp gets assigned a timestamp before @data.fromTimestamp. In this case
        # skipping this job was wrong. But this is (among other reasons) why we have that enqueue of an
        # extra job at the end of run method, which should handle such a case.
        'data.toTimestamp': null
      ,
        'data.toTimestamp':
          $gt: @data.fromTimestamp
      ]
      status:
        $in: JobsWorker.collection.jobStatusCancellable
    ,
      # Making findOne similar to exists.
      fields:
        _id: 1
      transform: null

  run: ->
    fromTimestamp = @data.fromTimestamp
    toTimestamp = new Date()

    JobsWorker.collection.update @_id,
      $set:
        'data.toTimestamp': toTimestamp

    @processActivities Activity.documents.find(
      timestamp:
        $gte: fromTimestamp
        $lt: toTimestamp
      level:
        $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]
    ,
      # Because we insert them into a local collection to be able to query them.
      transform: null
    ).fetch()

    futureActivitiesExist = Activity.documents.exists
      timestamp:
        $gte: toTimestamp
      level:
        $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]

    if futureActivitiesExist
      # ActivityEmailsJob is enqueued only if there is no existing job which would cover this timestamp.
      new ActivityEmailsJob(fromTimestamp: toTimestamp).enqueue()

  processActivities: (activities) ->
    # We insert activities into a local collection to be able to query them.
    class LocalActivity extends Activity
      @Meta
        name: 'LocalActivity'
        collection: null

    for activity in activities
      LocalActivity.documents.insert activity

    allUserIdsInActivities = []
    LocalActivity.documents.find().forEach (activity, index, cursor) =>
      for user in activity.forUsers when user?._id
        allUserIdsInActivities.push user._id

    allUserIdsInActivities = _.uniq allUserIdsInActivities

    css = fs.readFileSync [__meteor_bootstrap__.serverDir, '..', 'web.browser', 'merged-stylesheets.css'].join(pathModule.sep),
      encoding: 'utf8'

    User.documents.find(
      _id:
        $in: allUserIdsInActivities
    ,
      fields: _.extend User.REFERENCE_FIELDS(),
        _id: 1
        emails:
          $elemMatch:
            verified: true
    ).forEach (user, index, cursor) =>
      # TODO: Allow configuring which e-mail address is used for notifications.
      address = user.emails?[0]?.address
      return unless address

      uncombinedUserActivities = LocalActivity.documents.find(Activity.personalizedActivityQuery(user._id)).fetch()
      userActivities = Activity.combineActivities uncombinedUserActivities

      return unless userActivities.length

      emailId = Random.id()

      emailComponent = new ActivityEmailsComponent(userActivities, emailId)

      # DOCTYPE cannot be a part of the template.
      html = '<!DOCTYPE html>' + emailComponent.renderComponentToHTML()

      # Inline all CSS.
      html = juice.inlineContent html, css

      html = @_convertHTML html

      # Email is our document class and not Package.email.Email.
      Email.send emailId,
        from: Accounts.emailTemplates.from
        to: address
        subject: "[#{Accounts.emailTemplates.siteName}] Recent notifications"
        text: emailComponent.renderComponentToPlainText()
        html: html
        headers:
          Precedence: 'bulk'
      ,
        user, 'activities',
          activities: (_id: activity._id for activity in uncombinedUserActivities)

  _convertHTML: (html) ->
    $ = cheerio.load html,
      # Normalize whitespace.
      # TODO: Probably not necessary once: https://github.com/meteor/blaze/issues/88
      normalizeWhitespace: true
      xmlMode: false
      decodeEntities: true

    # Make links absolute URLs.
    $.root().find('a[href]').each (index, element) =>
      $element = $(element)
      $element.attr('href', url.resolve Meteor.absoluteUrl(), $element.attr('href'))

    # Make image sources absolute URLs.
    $.root().find('img[src]').each (index, element) =>
      $element = $(element)
      $element.attr('src', url.resolve Meteor.absoluteUrl(), $element.attr('src'))

    # Because we inlined all CSS, we can remove all classes.
    $.root().find('[class]').each (index, element) =>
      $element = $(element)
      $element.removeAttr('class')

    # Tag "nav" is not supported in Gmail, so we replace it with "div".
    # Because we already inlined all CSS, this does not make CSS not match.
    $.root().find('nav').each (index, element) =>
      element.tagName = 'div'

    $.html()
