SERVICES =
  facebook: [
    'appId'
    'secret'
  ]
  google: [
    'clientId'
    'secret'
  ]
  twitter: [
    'consumerKey'
    'secret'
  ]

Meteor.startup ->
  for serviceName, keys of SERVICES when Meteor.settings.services?[serviceName]
    values = _.pick Meteor.settings.services[serviceName], keys
    if _.keys(values).length is keys.length
      # Add a configuration entry.
      ServiceConfiguration.configurations.upsert
        service: serviceName
      ,
        $set: values
    else
      # Remove a potential configuration entry.
      ServiceConfiguration.configurations.remove
        service: serviceName

origUpdateOrCreateUserFromExternalService = Accounts.updateOrCreateUserFromExternalService
Accounts.updateOrCreateUserFromExternalService = (serviceName, serviceData, options) ->
  return origUpdateOrCreateUserFromExternalService.apply this, arguments unless serviceName in _.keys SERVICES

  if User.documents.exists("services.#{serviceName}.id": serviceData.id)
    # Or the current user is the same as the user being signed in (then we continue to update
    # the user document with new service data), or it is different and then we continue to
    # switch to this different user.
    return origUpdateOrCreateUserFromExternalService.apply this, arguments

  userId = Meteor.userId()

  # If user is not already signed in, then we do not allow them to sign in
  # but require them to first sign in with username and password.
  throw new Meteor.Error 'unauthorized', "You can sign in using #{_.capitalize serviceName} only after you linked that account to your existing PeerMind account." unless userId

  setServiceData = {}
  for key, value of serviceData
    setServiceData["services.#{serviceName}.#{key}"] = value

  User.documents.update
    _id: userId
  ,
    $set: setServiceData

  type: serviceName
  userId: userId
