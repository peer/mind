class Activity extends share.BaseDocument
  # timestamp: time of activity
  # connection
  # byUser:
  #   _id
  #   username
  #   avatar
  # forUsers: list of:
  #   _id
  #   username
  #   avatar
  # type: type of activity
  # level: one of Activity.LEVEL values
  # data: custom data for this activity

  @Meta
    name: 'Activity'
    collection: 'Activities'
    fields: =>
      byUser: @ReferenceField User, User.REFERENCE_FIELDS(), false
      forUsers: [
        @ReferenceField User, User.REFERENCE_FIELDS()
      ]
      data:
        comment: @ReferenceField Comment, [], false
        motion: @ReferenceField Motion, [], false
        point: @ReferenceField Point, ['category'], false
        meeting: @ReferenceField Meeting, ['title'], false
        discussion: @ReferenceField Discussion, ['title'], false
        email: @ReferenceField Email, [], false
        activity: @ReferenceField 'self', [], false
    triggers: =>
      sendEmails: @Trigger ['timestamp', 'level'], (newDocument, oldDocument) ->
        # Only trigger when document is created.
        return unless newDocument?._id and not oldDocument

        # Small optimization, because we send e-mails only for those levels.
        return unless newDocument.level in [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]

        # ActivityEmailsJob is enqueued only if there is no existing job which would cover this timestamp.
        # We depend on jobs package in an unordered mode to break a dependency cycle,
        # so we have to use the full package path to access a job.
        new Package.jobs.ActivityEmailsJob(fromTimestamp: newDocument.timestamp).enqueue()

  @LEVEL:
    DEBUG: 'debug'
    ERROR: 'error'
    ADMIN: 'admin'
    USER: 'user'
    GENERAL: 'general'

  @PUBLISH_FIELDS: ->
    if userId = Meteor.userId()
      forUsers =
        forUsers:
          $elemMatch:
            _id: userId
    else
      forUsers = {}

    _.extend super, forUsers,
      timestamp: 1
      byUser: 1
      type: 1
      level: 1
      data: 1

  @personalizedActivityQuery: (userId) ->
    level:
      $in: [Activity.LEVEL.USER, Activity.LEVEL.GENERAL]
    'byUser._id':
      $ne: userId
    'forUsers._id': userId

  # Combine documents so that consecutive activities of the same type are combined into one document.
  @combineActivities: (documents) ->
    combinedDocuments = []

    for document in documents
      if combinedDocuments.length is 0
        combinedDocuments.push document
        continue

      previousDocument = combinedDocuments[combinedDocuments.length - 1]
      if previousDocument.type is document.type
        # If categories are not the same, do not combine documents.
        if previousDocument.data.point?.category and previousDocument.data.point.category isnt document.data.point.category
          combinedDocuments.push document
          continue

        # If both documents are for the same discussion, combine them.
        if previousDocument.data.discussion?._id and previousDocument.data.discussion._id is document.data.discussion._id
          # But not if it is a mention from different places.
          if previousDocument.type is 'mention' and ((previousDocument.data.comment and not document.data.comment) or (previousDocument.data.point and not document.data.point) or (previousDocument.data.motion and not document.data.motion))
            combinedDocuments.push document
            continue

          previousDocument.laterDocuments ?= []
          previousDocument.combinedDocumentsCount ?= 1
          previousDocument.laterDocuments.push document
          previousDocument.combinedDocumentsCount++
          continue

      # We show only a user-level activity if both are available for same motion, one direction.
      else if (previousDocument.type is 'competingMotionOpened' and document.type is 'motionOpened') or (previousDocument.type is 'votedMotionClosed' and document.type is 'motionClosed')
        if previousDocument.timestamp.valueOf() is document.timestamp.valueOf() and previousDocument.data.motion._id is document.data.motion._id
          # We skip this document.
          previousDocument.combinedDocumentsCount ?= 1
          previousDocument.combinedDocumentsCount++
          continue

      # We show only a user-level activity if both are available for same motion, the other direction.
      else if (previousDocument.type is 'motionOpened' and document.type is 'competingMotionOpened') or (previousDocument.type is 'motionClosed' and document.type is 'votedMotionClosed')
        if previousDocument.timestamp.valueOf() is document.timestamp.valueOf() and previousDocument.data.motion._id is document.data.motion._id
          # We remove the previous (last) document, so that only this document is added to combinedDocuments.
          previousDocument.combinedDocumentsCount ?= 1
          document.combinedDocumentsCount = previousDocument.combinedDocumentsCount
          document.combinedDocumentsCount++
          combinedDocuments.pop()

      combinedDocuments.push document

    combinedDocuments

if Meteor.isServer
  Activity.Meta.collection._ensureIndex
    timestamp: 1

  Activity.Meta.collection._ensureIndex
    type: 1
