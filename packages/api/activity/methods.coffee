Meteor.methods
  'Activity.seenPersonalized': (activityId) ->
    check activityId, Match.DocumentId

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    timestamp = Activity.documents.findOne(activityId)?.timestamp
    throw new Meteor.Error 'not-found', "Activity '#{activityId}' cannot be found." unless timestamp

    User.documents.update
      _id: userId
      $or: [
        lastSeenPersonalizedActivity:
          $lt: timestamp
      ,
        lastSeenPersonalizedActivity: null
      ]
    ,
      $set:
        lastSeenPersonalizedActivity: timestamp
