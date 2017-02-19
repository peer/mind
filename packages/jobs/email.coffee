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
WHITESPACE = /\s+/g
ENDS_WITH_PUNCTUATION = /[.!?]$/

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

ToSubjectVisitor = ToPlainTextVisitor.extend()
ToSubjectVisitor.def
  # We do not include links in subjects.
  _joinLinks: ->
    ''

  # No extra newlines.
  _optionalNewline: (content) ->
    content

class ActivityEmailsComponent extends UIComponent
  @register 'ActivityEmailsComponent'

  constructor: (@title, @activities, @emailId) ->
    super

  instrument: ->
    return unless Package.instrument

    "?#{@emailId}"

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

class ActivityEmailsComponent.Subject extends UIComponent
  @register 'ActivityEmailsComponent.Subject'

  constructor: (@activities) ->
    super

  renderSubject: ->
    subjectText = @_renderComponentTo new ToSubjectVisitor()

    subjectText = subjectText.replace WHITESPACE, ' '

    subjectText = subjectText.trim()

    subjectText.replace ENDS_WITH_PUNCTUATION, ''

class ActivityEmailsJob extends Job
  # Every how many users do we log progress.
  LOG_PROGRESS_EVERY_USERS: 50

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

  processActivities: (fromTimestamp, toTimestamp) ->
    activities = Activity.documents.find(
      timestamp:
        $gte: fromTimestamp
        $lt: toTimestamp
      level:
        $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]
    ,
      # Because we insert them into a local collection to be able to query them.
      transform: null
    ).fetch()

    # We insert activities into a local collection to be
    # able to query them multiple times, cached, frozen.
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

    users = User.documents.find(
      _id:
        $in: allUserIdsInActivities
      # A slight optimization. Do not process at all users
      # who do not have at least one set to true.
      $or: [
        "emailNotifications.user#{@SETTINGS_FIELD_SUFFIX}": true
      ,
        "emailNotifications.general#{@SETTINGS_FIELD_SUFFIX}": true
      ]
    ,
      fields: _.extend User.REFERENCE_FIELDS(),
        _id: 1
        "emailNotifications.user#{@SETTINGS_FIELD_SUFFIX}": 1
        "emailNotifications.general#{@SETTINGS_FIELD_SUFFIX}": 1
        emails:
          $elemMatch:
            verified: true
    )

    usersCount = users.count()
    users.forEach (user, index, cursor) =>
      # TODO: Allow configuring which e-mail address is used for notifications.
      address = user.emails?[0]?.address
      unless address
        @usersProgress index, usersCount
        return

      uncombinedUserActivities = LocalActivity.documents.find(Activity.personalizedActivityQuery(user._id, user.emailNotifications?["user#{@SETTINGS_FIELD_SUFFIX}"], user.emailNotifications?["general#{@SETTINGS_FIELD_SUFFIX}"]),
        sort:
          # The newest first.
          timestamp: -1
      ).fetch()
      userActivities = Activity.combineActivities uncombinedUserActivities

      unless userActivities.length
        @usersProgress index, usersCount
        return

      emailId = Random.id()

      emailComponent = new ActivityEmailsComponent(@TITLE, userActivities, emailId)

      # DOCTYPE cannot be a part of the template.
      html = '<!DOCTYPE html>' + emailComponent.renderComponentToHTML()

      # Inline all CSS.
      html = juice.inlineContent html, css

      html = @_convertHTML html

      # Email is our document class and not Package.email.Email.
      Email.send emailId,
        from: Accounts.emailTemplates.from
        to: address
        subject: "[#{Accounts.emailTemplates.siteName}] #{@subject userActivities}"
        text: emailComponent.renderComponentToPlainText()
        html: html
        headers:
          Precedence: 'bulk'
      ,
        user, 'activities',
          activities: (_id: activity._id for activity in uncombinedUserActivities)
          type: @type()

      @usersProgress index, usersCount

    activitiesInRange: activities.length
    fromTimestamp: fromTimestamp
    toTimestamp: toTimestamp

  usersProgress: (index, usersCount) ->
    # Set progress on every LOG_PROGRESS_EVERY_USERS user.
    # We use index and not index + 1 so that we set the number of
    # total users with initial call to this method.
    return if index % @LOG_PROGRESS_EVERY_USERS isnt 0

    # A false return value from @progress means job has been probably canceled.
    # We throw an error to terminate the execution of this job.
    throw new Error "Unable to log progress." unless @progress index + 1, usersCount

  # We have to try to make each subject for each e-mail different,
  # so that Gmail does combine them all in one thread.
  subject: (activities) ->
    throw new Error "Not implemented."

class ActivityEmailsImmediatelyJob extends ActivityEmailsJob
  @register()

  TITLE: "Recent notifications"
  DELAY: 60 * 1000 # ms
  SETTINGS_FIELD_SUFFIX: 'Immediately'

  enqueueOptions: (options) ->
    _.defaults super,
      delay: @DELAY

  shouldSkip: (options) ->
    # Does a job which could handle activities for this job's timestamp exists already?
    # It could be that it is already running, but that will not process all activities
    # which exists at this moment since fromTimestamp. This is OK, because at the end of
    # its run it will schedule a new job to handle any remaining activities.
    # It could be that it ran, but it failed, sending none or partial amount of e-mails
    # already. In this case we do not want to resend e-mails again to those who might
    # already received them, so we see a failed job as a succeeded job for that time span.
    # TODO: Because we store with each e-mail for which user it is and for which activity, we could recover from partially done job (and failed).
    #       For job retries (but not for the first try, to optimize) we could check if any e-mail
    #       we are about to send has already been sent and skip it. But let us first see how many
    #       failures will there be during these jobs at all.
    !!JobsWorker.collection.findOne
      type: @type()
      'data.fromTimestamp':
        $lte: @data.fromTimestamp
      $or: [
        'result.toTimestamp': null
        status:
          # We do not want any job which fails before it sets result.toTimestamp
          # to prevent all future jobs to be enqueued.
          $in: JobsWorker.collection.jobStatusCancellable
      ,
        'result.toTimestamp':
          # We use $gt and not $gte here, because in the query for activities, we do "$lt: toTimestamp",
          # so for @data.fromTimestamp to be included, result.toTimestamp has to be strictly greater.
          # If a job processing this timestamp range runs on a worker with imprecise clock, then it might
          # happen that toTimestamp gets assigned a timestamp before @data.fromTimestamp. In this case
          # skipping this job was wrong. But this is (among other reasons) why we have that enqueue of an
          # extra job at the end of run method, which should handle such a case.
          $gt: @data.fromTimestamp
      ]
    ,
      # Making findOne similar to exists.
      fields:
        _id: 1
      transform: null

  run: ->
    fromTimestamp = @data.fromTimestamp
    toTimestamp = new Date()

    # We store toTimestamp before running the rest, so that even if the job fails, we know
    # which time span this job processed (or had to process). We see that time span as
    # successfully processed in any case. See comment in shouldSkip for reasoning.
    JobsWorker.collection.update @_id,
      $set:
        'result.fromTimestamp': fromTimestamp
        'result.toTimestamp': toTimestamp

    # Based on shouldSkip, it is not really possible to have two jobs overlapping.
    # Or this job had result.toTimestamp set to null, so no later job got scheduled,
    # or we just set result.toTimestamp, which also prevents an overlapping job to get scheduled.
    impossibleJobs = JobsWorker.collection.find(
      # We do not want to match this job.
      _id:
        $ne: @_id
      type: @type()
      'data.fromTimestamp':
        $lt: toTimestamp
      $or: [
        'result.toTimestamp': null
        status:
          # There might be some old failed job without result.toTimestamp.
          # We do not care about it overlapping with this job.
          $in: JobsWorker.collection.jobStatusCancellable
      ,
        'result.toTimestamp':
          $gt: fromTimestamp
      ]
    ).fetch()

    assert not impossibleJobs.length, "Overlapping job(s): #{_.pluck(impossibleJobs, '_id').join ', '}"

    try
      @processActivities fromTimestamp, toTimestamp
    finally
      # Even if this job failed, we continue with the next time span. We see this time span
      # as successfully processed. See comment in shouldSkip for reasoning.

      # To handle any edge cases where shouldSkip could prevent a job to be enqueued
      # for the next time span, we check here if there is any activity for which a job
      # is needed and try to enqueued it. If a suitable job already exists (which covers
      # this next time span), a new job will not be enqueued.
      futureActivitiesExist = Activity.documents.exists
        timestamp:
          $gte: toTimestamp
        level:
          $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]

      if futureActivitiesExist
        # ActivityEmailsImmediatelyJob is enqueued only if there is no existing job which would cover this timestamp.
        new ActivityEmailsImmediatelyJob(fromTimestamp: toTimestamp).enqueue()

  subject: (activities) ->
    subjectText = new ActivityEmailsComponent.Subject(activities).renderSubject()

    if activities.length is 2
      subjectText = "#{subjectText} (and one other notification)"
    else if activities.length > 2
      subjectText = "#{subjectText} (and #{activities.length - 1} other notifications)"

    subjectText

class ActivityEmailsDigestJob extends ActivityEmailsJob
  enqueueOptions: (options) ->
    _.defaults super,
      repeat:
        # TODO: Support other timezones.
        #       See: https://github.com/vsivsi/meteor-job-collection/issues/104
        #       This is in system's local timezone. later.js is configured to
        #       use local timezone in core/documents/jobqueue.coffee.
        schedule: JobsWorker.collection.later.parse.text @SCHEDULE
      save:
        # This makes it so that job of each class can exist only once, and every time
        # a job is enqueued, all previous (potentially with obsolete configuration) jobs
        # of the same class/type are canceled.
        cancelRepeats: true

  run: ->
    # We are assuming that there is only one job running at a time.
    # Once a job sets its result.toTimestamp we do not really care if it succeeded or failed.
    # We do not process that time span anymore, because job could send partial amount of e-mails
    # already. In this case we do not want to resend e-mails again to those who might
    # already received them, so we see a failed job as a succeeded job for that time span.
    # TODO: Because we store with each e-mail for which user it is and for which activity, we could recover from partially done job (and failed).
    #       For job retries (but not for the first try, to optimize) we could check if any e-mail
    #       we are about to send has already been sent and skip it. But let us first see how many
    #       failures will there be during these jobs at all.
    latestJob = JobsWorker.collection.findOne
      type: @type()
      'result.toTimestamp':
        $ne: null
    ,
      sort:
        'result.toTimestamp': -1
      fields:
        'result.toTimestamp': 1

    fromTimestamp = latestJob?.result?.toTimestamp or new Date(0)
    toTimestamp = new Date()

    if (toTimestamp.valueOf() - fromTimestamp.valueOf()) > @MAX_TIME_SPAN
      fromTimestamp = new Date toTimestamp.valueOf() - @MAX_TIME_SPAN

    # In theory there could be a large delay between findOne query above and until this update
    # query finishes. This could lead to a race condition. But because we run digest e-mails
    # with at least hours between them, we should be good here.
    JobsWorker.collection.update @_id,
      $set:
        'result.fromTimestamp': fromTimestamp
        'result.toTimestamp': toTimestamp

    @processActivities fromTimestamp, toTimestamp

  subject: (activities) ->
    subjectText = "#{@TITLE} #{@subjectTime()}"

    if activities.length is 1
      subjectText = "#{subjectText} (#{activities.length} notification)"
    else
      subjectText = "#{subjectText} (#{activities.length} notifications)"

    subjectText

  subjectTime: ->
    throw new Error "Not implemented."

class ActivityEmails4hoursDigestJob extends ActivityEmailsDigestJob
  @register()

  TITLE: "4-hour digest"
  MAX_TIME_SPAN: 4.5 * 60 * 60 * 1000 # ms
  SCHEDULE: 'every 4 hours'
  SETTINGS_FIELD_SUFFIX: '4hours'

  subjectTime: ->
    # We require the job object to exist.
    timestamp = JobsWorker.collection.findOne(@_id, fields: after: 1).after

    moment(timestamp).format 'l LT'

class ActivityEmailsDailyDigestJob extends ActivityEmailsDigestJob
  @register()

  TITLE: "Daily digest"
  MAX_TIME_SPAN: 24.5 * 60 * 60 * 1000 # ms
  SCHEDULE: 'at 7:40 AM'
  SETTINGS_FIELD_SUFFIX: 'Daily'

  subjectTime: ->
    # We require the job object to exist.
    timestamp = JobsWorker.collection.findOne(@_id, fields: after: 1).after

    moment(timestamp).format 'l'

class ActivityEmailsWeeklyDigestJob extends ActivityEmailsDigestJob
  @register()

  TITLE: "Weekly digest"
  MAX_TIME_SPAN: 7.5 * 24 * 60 * 60 * 1000 # ms
  SCHEDULE: 'on Monday at 7:20 AM'
  SETTINGS_FIELD_SUFFIX: 'Weekly'

  subjectTime: ->
    # We require the job object to exist.
    timestamp = JobsWorker.collection.findOne(@_id, fields: after: 1).after

    moment(timestamp).format 'l'

Meteor.startup ->
  new ActivityEmails4hoursDigestJob().enqueue()
  new ActivityEmailsDailyDigestJob().enqueue()
  new ActivityEmailsWeeklyDigestJob().enqueue()