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
}
