fs = Npm.require 'fs'
htmlModule = Npm.require 'html'
juice = Npm.require 'juice'
pathModule = Npm.require 'path'
url = Npm.require 'url'

class ActivityEmailsComponent extends UIComponent
  @register 'ActivityEmailsComponent'

  constructor: (@activities) ->
    super

  instrument: ->
    # TODO

class ActivityEmailsJob extends Job
  @register()

  @DELAY = 0 #60 * 1000 # ms

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
    # We are loading packages in unordered mode, so we are fixing imports here, if needed.
    Activity = Package.core.Activity unless Activity
    Email = Package.core.Email unless Email
    User = Package.core.User unless User

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
    # We are loading packages in unordered mode, so we are fixing imports here, if needed.
    Activity = Package.core.Activity unless Activity
    Email = Package.core.Email unless Email
    User = Package.core.User unless User

    class LocalActivity extends Activity
      @Meta
        name: 'LocalActivity'
        collection: null

    for activity in activities
      LocalActivity.documents.insert activity

    css = fs.readFileSync [__meteor_bootstrap__.serverDir, '..', 'web.browser', 'merged-stylesheets.css'].join(pathModule.sep),
      encoding: 'utf8'

    # TODO: Remove once this is fixed: https://github.com/Automattic/juice/issues/244
    css += """
      html {
        font-size: 14px;
      }
    """

    User.documents.find(
      # TODO: We should query relevant and active users for activities in a better way, especially once we have groups.
      roles:
        $exists: true
        $ne: []
      'emails.verified': true
    ,
      fields:
        _id: 1
        emails:
          $elemMatch:
            verified: true
    ).forEach (user, index, cursor) =>
      # TODO: Allow configuring which e-mail address is used for notifications.
      address = user.emails?[0]?.address
      return unless address

      userActivities = Activity.combineActivities LocalActivity.documents.find(Activity.personalizedActivityQuery(user._id)).fetch()

      return unless userActivities.length

      emailId = Random.id()

      # DOCTYPE cannot be a part of the template.
      html = @_absoluteURLs '<!DOCTYPE html>' + new ActivityEmailsComponent(userActivities, emailId).renderComponentToHTML()

      # Inline all CSS.
      html = juice.inlineContent html, css

      Email.send
        _id: emailId
        from: Accounts.emailTemplates.from
        to: address
        subject: "[#{Accounts.emailTemplates.siteName}] Recent notifications"
        # TODO
        text: ""
        html: html
        headers:
          Precedence: 'bulk'

  _absoluteURLs: (html) ->
    $ = cheerio.load html,
      # Normalize whitespace.
      # TODO: Probably not necessary once: https://github.com/meteor/blaze/issues/88
      normalizeWhitespace: true
      xmlMode: false
      decodeEntities: true

    $.root().find('a[href]').each (index, element) =>
      $element = $(element)
      $element.attr('href', url.resolve Meteor.absoluteUrl(), $element.attr('href'))

    $.root().find('img[src]').each (index, element) =>
      $element = $(element)
      $element.attr('src', url.resolve Meteor.absoluteUrl(), $element.attr('src'))

    $.html()
