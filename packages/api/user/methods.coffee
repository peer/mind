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
