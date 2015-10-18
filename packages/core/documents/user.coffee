class User extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last user app activity (login, password change, authored anything, voted on anything, etc.)
  # username: user's username
  # emails: list of
  #   address: e-mail address
  #   verified: is e-mail address verified
  # services: list of authentication/linked services

  @Meta
    name: 'User'
    collection: Meteor.users
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['username', 'emails']
      lastActivity: share.LastActivityTrigger ['services']

  @REFERENCE_FIELDS: ->
    _id: 1
    username: 1

  getReference: ->
    _.pick @, _.keys @constructor.REFERENCE_FIELDS()

Meteor.user = (userId, fields) ->
  if not fields and _.isObject userId
    fields = userId
    userId = null

  # Meteor.userId is reactive
  userId ?= Meteor.userId()
  fields ?= {}

  return null unless userId

  User.documents.findOne
    _id: userId
  ,
    fields: fields

# Forbid users from making any modifications to their user document.
User.Meta.collection.deny
  update: ->
    true
