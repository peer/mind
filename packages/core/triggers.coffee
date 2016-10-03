# Updates the lastActivity field when any of provided fields of a document change.
class LastActivityTriggerClass extends share.BaseDocument._Trigger
  updateLastActivity: (id, timestamp) ->
    @document.documents.update
      _id: id
      $or: [
        lastActivity:
          $lt: timestamp
      ,
        lastActivity: null
      ]
    ,
      $set:
        lastActivity: timestamp

  constructor: (fields, trigger) ->
    super fields, trigger or (newDocument, oldDocument) ->
      # Don't do anything when document is removed.
      return unless newDocument?._id

      # Don't do anything if there was no change.
      return if _.isEqual newDocument, oldDocument

      timestamp = new Date()
      @updateLastActivity newDocument._id, new Date()

share.LastActivityTrigger = (args...) ->
  new LastActivityTriggerClass args...

# Updates the lastActivity field of a related document when
# any of provided fields of a document change.
class RelatedLastActivityTriggerClass extends Document._Trigger
  updateLastActivity: (id, timestamp) ->
    @relatedDocument.documents.update
      _id: id
      $or: [
        lastActivity:
          $lt: timestamp
      ,
        lastActivity: null
      ]
    ,
      $set:
        lastActivity: timestamp

  constructor: (@relatedDocument, fields, @relatedIds) ->
    super fields, (newDocument, oldDocument) ->
      # Don't do anything when document is removed.
      return unless newDocument?._id

      # Don't do anything if there was no change.
      return if _.isEqual newDocument, oldDocument

      timestamp = new Date()
      relatedIds = @relatedIds newDocument, oldDocument
      relatedIds = [relatedIds] unless _.isArray relatedIds
      for relatedId in relatedIds when relatedId
        @updateLastActivity relatedId, timestamp

share.RelatedLastActivityTrigger = (args...) ->
  new RelatedLastActivityTriggerClass args...

# When any content fields (provided fields) of a document
# change we update both updatedAt and lastActivity fields.
class UpdatedAtTriggerClass extends LastActivityTriggerClass
  updateUpdatedAt: (id, timestamp) ->
    @document.documents.update
      _id: id
      $or: [
        updatedAt:
          $lt: timestamp
      ,
        updatedAt: null
      ]
    ,
      $set:
        updatedAt: timestamp

  constructor: (fields, noLastActivity) ->
    super fields, (newDocument, oldDocument) ->
      # Don't do anything when document is removed.
      return unless newDocument?._id

      # Don't do anything if there was no change.
      return if _.isEqual newDocument, oldDocument

      timestamp = new Date()
      @updateUpdatedAt newDocument._id, timestamp

      # Every time we update updatedAt, we update lastActivity as well.
      @updateLastActivity newDocument._id, timestamp unless noLastActivity

share.UpdatedAtTrigger = (args...) ->
  new UpdatedAtTriggerClass args...

# Adds mentioned users to followers of the discussions
class MentionsTriggerClass extends share.BaseDocument._Trigger
  constructor: (mentionsField, discussionField) ->
    super [mentionsField, discussionField], (newDocument, oldDocument) ->
      # Don't do anything when document is removed.
      return unless newDocument?._id

      discussionId = _.path newDocument, discussionField

      # Change of a discussion should not really happen, but let's handle it.
      if oldDocument and discussionId isnt _.path(oldDocument, discussionField)
        # We just pretend it is a new document.
        oldDocument = null

      newMentions = _.pluck _.path(newDocument, mentionsField), '_id'
      oldMentions = _.pluck _.path(oldDocument, mentionsField), '_id'

      addedMentions = _.difference newMentions, oldMentions

      for addedMention in addedMentions
        Discussion.documents.update
          _id: discussionId
          'followers.user._id':
            $ne: addedMention
        ,
          $addToSet:
            followers:
              user:
                _id: addedMention
              reason: Discussion.REASON.MENTIONED

share.MentionsTrigger = (args...) ->
  new MentionsTriggerClass args...
