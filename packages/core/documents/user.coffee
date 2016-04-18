# "i" is a suffix for automatically generated initials.
AVATAR_INITIALS_REGEX = ///^avatar/\w+-i\.///

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
      avatar: @GeneratedField 'self', ['avatar', 'username'], (fields) =>
        # Do not do anything if a custom avatar (no "i" suffix) is set.
        return [] if fields.avatar and not AVATAR_INITIALS_REGEX.test fields.avatar

        # "i" is a suffix for automatically generated initials.
        avatarFilename = "avatar/#{fields._id}-i.svg"
        avatarContent = @generateAvatar fields.username

        sha256 = new Crypto.SHA256
          size: avatarContent.length
        sha256.update avatarContent
        avatarHash = sha256.finalize()

        Storage.save avatarFilename, avatarContent

        # Attach a query string to force reactive client-side update when the content changes.
        [fields._id, "#{avatarFilename}?#{avatarHash.substr 0, 16}"]
    triggers: =>
      updatedAt: share.UpdatedAtTrigger ['username', 'emails']
      lastActivity: share.LastActivityTrigger ['services']

  @REFERENCE_FIELDS: ->
    _id: 1
    username: 1
    avatar: 1

  @EXTRA_PUBLISH_FIELDS: ->
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
    USER_ADMIN: 'USER_ADMIN'

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
      @PERMISSIONS.USER_ADMIN
    ]

  # Currently with roles 1.0 package we do not really assign to users permissions, but
  # just roles. So here we are mapping permissions to all roles which have those permissions.
  # TODO: Change all this logic when we migrate to roles 2.0 package.
  @_convertToRoles: (permissions) ->
    permissions = [permissions] unless _.isArray permissions

    roles = []

    for permission in permissions
      found = false
      for knownPermissionKey, knownPermissionValue of @PERMISSIONS
        if knownPermissionValue is permission
          found = true
          break

      # We want to be strict and catch any invalid permission. One should
      # be using constants and not strings directly anyway.
      throw new Error "Unknown permission '#{permission}'." unless found

      for roleKey, rolePermissions of @ROLES when permission in rolePermissions
        # All this is hard-coded for now. We convert to lower case.
        roles.push roleKey.toLowerCase()

    roles

  @hasPermission: (permissions) ->
    roles = @_convertToRoles permissions

    # We are using the peerlibrary:user-extra package to make this work everywhere.
    userId = Meteor.userId()
    return false unless userId

    Roles.userIsInRole userId, roles

  @withPermission: (permissions) ->
    roles = @_convertToRoles permissions

    # TODO: In roles 2.0 package getUsersInRole accepts an array as well.
    throw new Error "Currently only one role is supported." if roles.length isnt 1

    Roles.getUsersInRole roles[0]

  # Copied from: https://github.com/RocketChat/Rocket.Chat/blob/master/server/startup/avatar.coffee
  @generateAvatar: (username="") ->
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

  getReference: ->
    _.pick @, _.keys @constructor.REFERENCE_FIELDS()

if Meteor.isServer
  User.Meta.collection._ensureIndex
    createdAt: 1

  User.Meta.collection._ensureIndex
    updatedAt: 1

  User.Meta.collection._ensureIndex
    lastActivity: 1

  User.Meta.collection._ensureIndex
    roles: 1
