# Suffix can be:
#  i - for automatically generated initials
#  s - for generated default avatar for Sandstorm
#  u - for avatar uploaded by user
AVATAR_REGEX = ///^avatar/\w+-([isu])\.///

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

generateSandstormAvatar = (fields) ->
  # Sandstorm should always provide an avatar in newer versions.
  # See: https://github.com/sandstorm-io/sandstorm/issues/1866
  return [fields._id, fields.services.sandstorm.picture] if fields.services?.sandstorm?.picture

  # There is no avatar provided by Sandstorm. We do not support that.
  # TODO: Provide some better fallback avatar than null (which does not even exist)?
  return [fields._id, null]

generateAvatar = (fields) ->
  if fields.avatar and match = AVATAR_REGEX.exec fields.avatar
    # Do not do anything if a custom avatar (no "i" suffix) is set.
    return [] unless match[1] is 'i'

  # It is OK if fields.username does not exist.
  avatarContent = initialsAvatar fields.username

  updateAvatar fields._id, 'i', 'svg', avatarContent

updateAvatar = (usedId, type, extension, avatarContent) ->
  avatarFilename = "avatar/#{usedId}-#{type}.#{extension}"

  sha256 = new Crypto.SHA256
    size: avatarContent.length
  sha256.update avatarContent
  avatarHash = sha256.finalize()

  # TODO: Remove other types and extensions of previously stored avatars.
  Storage.save avatarFilename, avatarContent

  # Attach a query string to force reactive client-side update when the content changes.
  [usedId, "#{avatarFilename}?#{avatarHash.substr 0, 16}"]

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
  # avatar: avatar filename

  @Meta
    name: 'User'
    collection: Meteor.users
    fields: =>
      if __meteor_runtime_config__.SANDSTORM
        username: @GeneratedField 'self', ['services.sandstorm.preferredHandle'], generateSandstormUsername
        # We include "avatar" field so the if it gets deleted it gets regenerated.
        avatar: @GeneratedField 'self', ['avatar', 'services.sandstorm.picture'], generateSandstormAvatar
      else
        # We include "avatar" field so the if it gets deleted it gets regenerated.
        avatar: @GeneratedField 'self', ['avatar', 'username'], generateAvatar
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
      'services.facebook.id': 1
      'services.facebook.name': 1
      'services.facebook.link': 1
      'services.google.id': 1
      'services.google.name': 1
      'services.google.picture': 1

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

  avatarUrl: (service) ->
    if service is 'facebook'
     "https://graph.facebook.com/#{@services.facebook?.id}/picture"
    else if service is 'google'
     @services.google?.picture
    else
      if @avatar and AVATAR_REGEX.test @avatar
        Storage.url @avatar
      else
        @avatar

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
