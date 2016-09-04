_.mixin
  capitalize: (string) ->
    string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()

  startsWith: (string, start) ->
    string?.lastIndexOf(start, 0) is 0

  isPlainObject: (obj) ->
    if not _.isObject(obj) or _.isArray(obj) or _.isFunction(obj)
      return false

    if obj.constructor isnt Object
      return false

    return true