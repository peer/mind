Fiber = Npm.require('fibers')
parseUrl = Npm.require 'parseurl'

# TODO: Programmatically resolve the full image URL.
WebApp.rawConnectHandlers.use '/packages/peermind/layout/logo.png', (req, res, next) ->
  emailId = parseUrl(req).query

  return next() unless emailId

  try
    check emailId, Match.DocumentId
  catch error
    # Invalid e-mail ID, ignoring.
    next()
    return

  new Fiber(->
    # To make sure we do not got a fake e-mail ID and make references
    # to nonexistent documents. That would log errors.
    return unless Email.documents.exists
      _id: emailId

    Activity.documents.insert
      timestamp: new Date()
      connection: null
      byUser: null
      type: 'emailOpen'
      level: Activity.LEVEL.DEBUG
      data:
        email:
          _id: emailId
  ).run()

  # We can get here before document is really inserted, because fiber can yield,
  # but this is OK, it is OK to log the request in parallel.
  next()
