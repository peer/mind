Meteor.methods
  'User.profileUpdate': (profile) ->
    check profile, String

    user = Meteor.user User.REFERENCE_FIELDS()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    profile = Comment.sanitize.sanitizeHTML profile

    if profile
      if Meteor.isServer
        $root = cheerio.load(profile).root()
      else
        $root = $('<div/>').append($.parseHTML(profile))

      profileText = $root.text()

      # If content is empty, we set the profile to an empty string (instead of HTML tags without any content).
      # This helps us that we can display a message to a visitor that a profile is empty.
      profile = '' unless profileText or $root.has('figure').length

    attachments = User.extractAttachments profile
    mentions = User.extractMentions profile

    updatedAt = new Date()
    changed = User.documents.update
      _id: user._id
      profile:
        $ne: profile
    ,
      $set:
        updatedAt: updatedAt
        profile: profile
        profileAttachments: ({_id} for _id in attachments)
        profileMentions: ({_id} for _id in mentions)
      $push:
        changes:
          updatedAt: updatedAt
          author: user.getReference()
          profile: profile

    if changed
      StorageFile.documents.update
        _id:
          $in: attachments
      ,
        $set:
          active: true
      ,
        multi: true

    changed

  'User.removeDelegation': (userId) ->
    check userId, Match.DocumentId

    # We are manually fetching the user document so that we can disable transform.
    user = User.documents.findOne
      _id: Meteor.userId()
    ,
      fields:
        delegations: 1
      # We use no transform because we want delegations array exactly as it is.
      # We change it and store it back.
      transform:
        null
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    delegations = user.delegations or []
    # Deep clone so that normalizeDelegations can modify it at will.
    newDelegations = EJSON.clone (delegation for delegation in delegations when delegation.user?._id isnt userId)

    # Nothing was removed. This is also true if user.delegations does not exist.
    return 0 if delegations.length is newDelegations.length

    # user.delegations has to exist for us to be able to remove a document.
    assert user.delegations

    newDelegations = User.normalizeDelegations newDelegations

    User.documents.update
      _id: user._id
      # Only if nothing changed during execution of this method.
      delegations: user.delegations
    ,
      $set:
        delegations: newDelegations

  'User.setDelegation': (userId, value) ->
    check userId, Match.DocumentId
    check value, Number

    value = Math.min(Math.max(value or 0.0, 0.0), 1.0)

    # We are manually fetching the user document so that we can disable transform.
    user = User.documents.findOne
      _id: Meteor.userId()
    ,
      fields:
        delegations: 1
      # We use no transform because we want delegations array exactly as it is.
      # We change it and store it back.
      transform:
        null
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless user

    return 0 unless user.delegations

    # Deep clone so that we can modify it at will.
    newDelegations = EJSON.clone user.delegations

    # Just to make sure.
    newDelegations = User.normalizeDelegations newDelegations

    newDelegations = User.setDelegations newDelegations, userId, value

    # Nothing changed.
    return 0 if EJSON.equals user.delegations, newDelegations

    User.documents.update
      _id: user._id
      # Only if nothing changed during execution of this method.
      delegations: user.delegations
    ,
      $set:
        delegations: newDelegations
