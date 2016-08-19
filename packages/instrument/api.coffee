Meteor.methods
  'Activity.route': (routeName, params, queryParams, hash, path, oldRouteName) ->
    check routeName, Match.NonEmptyString
    check params, Object
    check queryParams, Object
    check hash, String
    check path, Match.NonEmptyString
    check oldRouteName, Match.OptionalOrNull Match.NonEmptyString

    if @userId
      user =
        _id: @userId
    else
      user = null

    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'route'
      visibility: Activity.VISIBILITY.INTERNAL
      data: {
        routeName
        params
        queryParams
        hash
        path
        oldRouteName: oldRouteName or null
      }
