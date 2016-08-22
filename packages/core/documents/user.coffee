if Meteor.isServer
  crypto = Npm.require 'crypto'

# Suffix can be:
#  i - for automatically generated initials
#  u - for avatar uploaded by user
AVATAR_REGEX = ///^avatar/\w+-([iu])\.///

generateSandstormUsername = (fields) ->
  return [] unless fields.services?.sandstorm?.preferredHandle

  # We start with 1 so that the first number to try is 2.
  counter = 1
  username = fields.services.sandstorm.preferredHandle

  loop
    try
      # This searches in a case insensitive way.
      user = Accounts.findUserByUsername username

      if user
        counter++
        username = "#{fields.services.sandstorm.preferredHandle}#{counter}"
        continue
      else
        Accounts.setUsername fields._id, username

      # Redundant, because we just set it, but we still return the same values.
      return [fields._id, username]

    catch error
      if /Username already exists/.test "#{error}"
        counter++
        username = "#{fields.services.sandstorm.preferredHandle}#{counter}"
        continue

      throw error

generateSandstormAvatars = (fields) ->
  return [] unless fields.services?.sandstorm?.picture

  [fields._id, [
    name: 'sandstorm'
    argument: null
    location: fields.services.sandstorm.picture
    selected: true
  ]]

updateAvatar = (usedId, type, extension, avatarContent) ->
  avatarFilename = "avatar/#{usedId}-#{type}.#{extension}"

  sha256 = new Crypto.SHA256
    size: avatarContent.length
  sha256.update avatarContent
  avatarHash = sha256.finalize()

  # TODO: Remove other types and extensions of previously stored avatars.
  Storage.save avatarFilename, avatarContent

  # Attach a query string to force reactive client-side update when the content changes.
  "#{avatarFilename}?#{avatarHash.substr 0, 16}"

# Copied from: https://github.com/RocketChat/Rocket.Chat/blob/master/server/startup/avatar.coffee
initialsAvatar = (username="") ->
  colors = ['#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39', '#FFC107', '#FF9800', '#FF5722', '#795548', '#9E9E9E', '#607D8B']

  position = username.length % colors.length
  color = colors[position]
  # TODO: Use slugify2.
  username = username.replace(/[^A-Za-z0-9]/g, '.').replace(/\.+/g, '.').replace(/(^\.)|(\.$)/g, '')
  usernameParts = username.split('.')
  if usernameParts.length > 1
    initials = _.first(usernameParts)[0] + _.last(usernameParts)[0]
  else
    initials = username.replace(/[^A-Za-z0-9]/g, '').substr(0, 2)
  initials = initials.toUpperCase()

  initials ||= "?"

  """
  <?xml version="1.0" encoding="UTF-8" standalone="no"?>
  <svg xmlns="http://www.w3.org/2000/svg" pointer-events="none" width="50" height="50" style="width: 50px; height: 50px; background-color: #{color};">
    <text text-anchor="middle" y="50%" x="50%" dy="0.36em" pointer-events="auto" fill="#ffffff" font-family="Helvetica, Arial, Lucida Grande, sans-serif" style="font-weight: 400; font-size: 28px;">
      #{initials}
    </text>
  </svg>
  """

generateAvatar = (fields) ->
  # Return selected avatar location.
  for avatar in fields.avatars or [] when avatar.selected
    return [fields._id, avatar.location]

  if __meteor_runtime_config__.SANDSTORM
    defaultAvatar = 'sandstorm'
  else
    defaultAvatar = 'default'

  # If no avatar is selected, return default avatar.
  for avatar in fields.avatars or [] when avatar.name is defaultAvatar
    return [fields._id, avatar.location]

  # Otherwise, do not do anything. The generateAvatars generator will update
  # this field with at least default avatar and this generator will run again.
  # (It generates a default avatar even if there is no username.)

  return []

currentlySelectedAvatar = (userId) =>
  user = User.documents.findOne
    _id: userId
    'avatars.selected': true
  ,
    fields:
      'avatars.$': 1

  return null unless user

  # Mongo query limited items in the array only to selected.
  # So we just pick the first item.
  user.avatars[0]

gravatarHash = (address) ->
  hash = crypto.createHash 'md5'
  hash.update address.trim().toLowerCase()
  hash.digest 'hex'

generateAvatars = (fields) ->
  avatars = []
  selectedAvatar = currentlySelectedAvatar fields._id

  # It is OK if fields.username does not exist.
  defaultAvatarContent = initialsAvatar fields.username

  defaultAvatarLocation = updateAvatar fields._id, 'i', 'svg', defaultAvatarContent

  avatars.push
    name: 'default'
    argument: null
    location: defaultAvatarLocation
    selected: selectedAvatar?.name is 'default'

  for email in fields.emails or [] when email.verified and email.address
    avatars.push
      name: 'gravatar'
      argument: email.address
      location: "https://www.gravatar.com/avatar/#{gravatarHash email.address}?d=identicon"
      selected: selectedAvatar?.name is 'gravatar'

  if fields.services?.facebook?.id
    avatars.push
      name: 'facebook'
      argument: null
      location: "https://graph.facebook.com/#{fields.services.facebook.id}/picture"
      selected: selectedAvatar?.name is 'facebook'

  if fields.services?.google?.picture
    avatars.push
      name: 'google'
      argument: null
      location: fields.services.google.picture
      selected: selectedAvatar?.name is 'google'

  if fields.services?.twitter?.profile_image_url_https
    avatars.push
      name: 'twitter'
      argument: null
      location: fields.services.twitter.profile_image_url_https
      selected: selectedAvatar?.name is 'twitter'

  if fields.uploadedAvatar
    avatars.push
      name: 'uploaded'
      argument: null
      location: fields.uploadedAvatar
      selected: selectedAvatar?.name is 'uploaded'

  # If no other is selected, select the default avatar.
  avatars[0].selected = true unless _.findWhere avatars, selected: true

  [fields._id, avatars]

class User extends share.BaseDocument
  # createdAt: time of document creation
  # updatedAt: time of the last change
  # lastActivity: time of the last user app activity (login, password change, authored anything, voted on anything, etc.)
  # username: user's username
  # emails: list of
  #   address: e-mail address
  #   verified: is e-mail address verified
  # services: list of authentication/linked services
  # roles: list of roles names (strings) this user is part of
  # avatar: avatar filename or URL
  # uploadedAvatar: filename of the uploaded avatar
  # avatars: list of available avatars
  #   name: name of the avatar (does not have to be unique, Gravatar can have multiple entries for example for each e-mail address)
  #   argument: any optional argument for generation of this avatar (like e-mail address for Gravatar)
  #   location: filename or URL
  #   selected: boolean if this is the preferred avatar
  # researchData: boolean if user consents to contributing data to a dataset

  @Meta
    name: 'User'
    collection: Meteor.users
    fields: =>
      # We include "avatar" field so the if it gets deleted it gets regenerated.
      fields =
        avatar: @GeneratedField 'self', ['avatar', 'avatars'], generateAvatar
      if __meteor_runtime_config__.SANDSTORM
        _.extend fields,
          username: @GeneratedField 'self', ['services.sandstorm.preferredHandle'], generateSandstormUsername
          avatars: [@GeneratedField 'self', ['services.sandstorm.picture'], generateSandstormAvatars]
      else
        _.extend fields,
          avatars: [@GeneratedField 'self', ['username', 'emails', 'services.facebook.id', 'services.google.picture', 'services.twitter.profile_image_url_https', 'uploadedAvatar'], generateAvatars]
      fields
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['username', 'emails']
      lastActivity: share.LastActivityTrigger ['services']

  @REFERENCE_FIELDS: ->
    _id: 1
    username: 1
    avatar: 1

  @EXTRA_PUBLISH_FIELDS: ->
    if __meteor_runtime_config__.SANDSTORM
      _id: 1
      avatar: 1
      'services.sandstorm.permissions': 1
    else
      _id: 1
      avatar: 1

  @PERMISSIONS:
    UPVOTE: 'UPVOTE'
    COMMENT_NEW: 'COMMENT_NEW'
    COMMENT_UPDATE: 'COMMENT_UPDATE'
    COMMENT_UPDATE_OWN: 'COMMENT_UPDATE_OWN'
    DISCUSSION_NEW: 'DISCUSSION_NEW'
    DISCUSSION_UPDATE: 'DISCUSSION_UPDATE'
    DISCUSSION_UPDATE_OWN: 'DISCUSSION_UPDATE_OWN'
    MEETING_NEW: 'MEETING_NEW'
    MEETING_UPDATE: 'MEETING_UPDATE'
    MEETING_UPDATE_OWN: 'MEETING_UPDATE_OWN'
    MOTION_NEW: 'MOTION_NEW'
    MOTION_UPDATE: 'MOTION_UPDATE'
    MOTION_UPDATE_OWN: 'MOTION_UPDATE_OWN'
    MOTION_OPEN_VOTING: 'MOTION_OPEN_VOTING'
    MOTION_CLOSE_VOTING: 'MOTION_CLOSE_VOTING'
    MOTION_WITHDRAW: 'MOTION_WITHDRAW'
    MOTION_WITHDRAW_OWN: 'MOTION_WITHDRAW_OWN'
    MOTION_VOTE: 'MOTION_VOTE'
    POINT_NEW: 'POINT_NEW'
    POINT_UPDATE: 'POINT_UPDATE'
    POINT_UPDATE_OWN: 'POINT_UPDATE_OWN'
    ACCOUNTS_ADMIN: 'ACCOUNTS_ADMIN'

  # TODO: Currently roles/permissions map is hard-coded, but change this when we migrate to roles 2.0 package.
  @ROLES:
    MEMBER: [
      @PERMISSIONS.UPVOTE
      @PERMISSIONS.COMMENT_NEW
      @PERMISSIONS.COMMENT_UPDATE_OWN
      @PERMISSIONS.DISCUSSION_NEW
      @PERMISSIONS.DISCUSSION_UPDATE_OWN
      @PERMISSIONS.MOTION_NEW
      @PERMISSIONS.MOTION_UPDATE_OWN
      @PERMISSIONS.MOTION_WITHDRAW_OWN
      @PERMISSIONS.MOTION_VOTE
    ]
    MANAGER: [
      @PERMISSIONS.COMMENT_NEW
      @PERMISSIONS.COMMENT_UPDATE_OWN
      @PERMISSIONS.DISCUSSION_NEW
      @PERMISSIONS.DISCUSSION_UPDATE_OWN
      @PERMISSIONS.MOTION_NEW
      @PERMISSIONS.MOTION_UPDATE_OWN
      @PERMISSIONS.MOTION_WITHDRAW_OWN
    ]
    # Moderators can create new meetings and points, and update them, but cannot
    # update own meetings and points, so that if they loose permissions they cannot
    # update anymore old meetings and points they made.
    MODERATOR: [
      @PERMISSIONS.COMMENT_UPDATE
      @PERMISSIONS.DISCUSSION_UPDATE
      @PERMISSIONS.MOTION_UPDATE
      @PERMISSIONS.MOTION_OPEN_VOTING
      @PERMISSIONS.MOTION_CLOSE_VOTING
      @PERMISSIONS.MOTION_WITHDRAW
      @PERMISSIONS.MEETING_NEW
      @PERMISSIONS.MEETING_UPDATE
      @PERMISSIONS.POINT_NEW
      @PERMISSIONS.POINT_UPDATE
    ]
    ADMIN: [
      @PERMISSIONS.ACCOUNTS_ADMIN
    ]

  @_checkPermissions: (permissions) ->
    permissions = [permissions] unless _.isArray permissions

    for permission in permissions
      found = false
      for knownPermissionKey, knownPermissionValue of @PERMISSIONS
        if knownPermissionValue is permission
          found = true
          break

      # We want to be strict and catch any invalid permission. One should
      # be using constants and not strings directly anyway.
      throw new Error "Unknown permission '#{permission}'." unless found

    permissions

  # Currently with roles 1.0 package we do not really assign to users permissions, but
  # just roles. So here we are mapping permissions to all roles which have those permissions.
  # TODO: Change all this logic when we migrate to roles 2.0 package.
  @_convertToRoles: (permissions) ->
    permissions = @_checkPermissions permissions

    roles = []

    for permission in permissions
      for roleKey, rolePermissions of @ROLES when permission in rolePermissions
        # All this is hard-coded for now. We convert to lower case.
        roles.push roleKey.toLowerCase()

    roles

  @hasPermission: (permissions) ->
    if __meteor_runtime_config__.SANDSTORM
      permissions = @_checkPermissions permissions

      # We are using the peerlibrary:user-extra package to make this work everywhere.
      userId = Meteor.userId()
      return false unless userId

      @documents.exists
        _id: userId
        'services.sandstorm.permissions':
          $in: permissions

    else
      roles = @_convertToRoles permissions

      # We are using the peerlibrary:user-extra package to make this work everywhere.
      userId = Meteor.userId()
      return false unless userId

      Roles.userIsInRole userId, roles

  @withPermission: (permissions) ->
    if __meteor_runtime_config__.SANDSTORM
      permissions = @_checkPermissions permissions

      @documents.find
        'services.sandstorm.permissions':
          $in: permissions

    else
      roles = @_convertToRoles permissions

      # TODO: In roles 2.0 package getUsersInRole accepts an array as well.
      throw new Error "Currently only one role is supported." if roles.length isnt 1

      Roles.getUsersInRole roles[0]

  getReference: ->
    _.pick @, _.keys @constructor.REFERENCE_FIELDS()

  avatarUrl: (service, argument) ->
    service = null if service instanceof Spacebars.kw
    argument = null if argument instanceof Spacebars.kw

    if service
      if argument
        avatarObject = _.findWhere @avatars,
          name: service
          argument: argument
      else
        avatarObject = _.findWhere @avatars,
          name: service

      avatar = avatarObject?.location

    else
      avatar = @avatar

    if avatar and AVATAR_REGEX.test avatar
      Storage.url avatar
    else
      avatar

if Meteor.isServer
  User.Meta.collection._ensureIndex
    createdAt: 1

  User.Meta.collection._ensureIndex
    updatedAt: 1

  User.Meta.collection._ensureIndex
    lastActivity: 1

  User.Meta.collection._ensureIndex
    roles: 1

  if __meteor_runtime_config__.SANDSTORM
    User.Meta.collection._ensureIndex
      'services.sandstorm.permissions': 1
