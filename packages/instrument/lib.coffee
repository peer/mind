escapeKeys = (object) ->
  if _.isArray object
    return (escapeKeys i for i in object)

  else if _.isPlainObject object
    result = {}
    for key, value of object
      # We replace $ at the beginning with \$, so that it is not at the beginning anymore.
      # We replace . anywhere with \_. We also replace \ with \\ so that we can unescape.
      key = key.replace(/\\/g, '\\\\').replace(/^\$/, '\\$').replace(/\./g, '\\_')
      result[key] = escapeKeys value
    return result

  else
    return object

routeObject = (context) ->
  routeName: context.route.name
  params: context.params
  queryParams: context.queryParams
  hash: context.context.hash
  path: context.context.canonicalPath
  oldRouteName: context.oldRoute?.name or null

routeObjectMatch =
  routeName: Match.NonEmptyString
  params: Object
  queryParams: Object
  hash: String
  path: Match.NonEmptyString
  oldRouteName: Match.OneOf Match.NonEmptyString, null

module.exports = {
  routeObject
  routeObjectMatch
  escapeKeys
}
