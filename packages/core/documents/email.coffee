class Email extends share.BaseDocument
  # createdAt: time of document creation
  # sentAt: time when e-mail was send
  # messageId: full e-mail message ID
  # from
  # to
  # forUser:
  #   _id
  #   username
  #   avatar
  # type: type of e-mail
  # data: custom related data for this e-mail

  @Meta
    name: 'Email'
    fields: =>
      forUser: @ReferenceField User, User.REFERENCE_FIELDS(), false
      data:
        activities: [
          @ReferenceField Activity, []
        ]

  @send: (emailId, emailOptions, forUser, type, data) ->
    throw new Error "Not supported." unless Meteor.isServer

    document = _.pick emailOptions, 'from', 'to'
    document._id = emailId
    document.createdAt = new Date()
    document.type = type or null
    document.data = data or null

    if forUser
      document.forUser = forUser.getReference()
    else
      document.forUser = null

    emailOptions.headers ?= {}
    emailOptions.headers['Message-ID'] ?= "<email-#{document._id}@peermind.org>"

    for header, value of emailOptions.headers when header.toLowerCase() is 'message-id'
      document.messageId = value
      break

    assert document.messageId

    @documents.insert document

    # We depend weakly, so that we can use Email symbol for our document class.
    Package.email.Email.send emailOptions

    @documents.update document._id,
      $set:
        sentAt: new Date()
