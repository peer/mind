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

  path: (object, path) ->
    return undefined unless _.isString path
    for segment in path.split '.'
      return undefined unless _.isObject(object) and segment of object
      object = object[segment]
    object

  # Kahan summation algorithm.
  preciseSum: (values...) ->
    values = _.flatten values

    sum = 0.0
    compensation = 0.0
    for value in values
      valueWithCompensation = value - compensation
      temp = sum + valueWithCompensation
      compensation = (temp - sum) - valueWithCompensation
      sum = temp

    sum
