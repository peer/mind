if Meteor.isServer
  EmailModule = require 'meteor/email'

class Email extends share.BaseDocument
  # createdAt: time of document creation
  # sentAt: time when e-mail was send
  # from
  # to
  # subject
  # text
  # html
  # headers

  @Meta
    name: 'Email'

  @send: (options) ->
    throw new Error "Not supported." unless Meteor.isServer

    options = _.extend {}, options,
      createdAt: new Date()

    options._id ?= Random.id()

    options.headers ?= {}
    options.headers['Message-ID'] ?= "<email-#{options._id}@peermind.org>"

    @documents.insert options

    EmailModule.Email.send options

    @documents.update options._id,
      $set:
        sentAt: new Date()
