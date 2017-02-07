CAMELIZE_RE = /-(\w)/g
HYPHENATE_RE = /([^-])([A-Z])/g

_.mixin
  capitalize: (string) ->
    string.charAt(0).toUpperCase() + string.substring(1).toLowerCase()

  startsWith: (string, start) ->
    string?.lastIndexOf(start, 0) is 0

  endsWith: (string, end) ->
    return false unless string

    lastIndex = string.length - 1
    string.indexOf(end, lastIndex) is lastIndex

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

  # Camelize a hyphen-delimited string.
  # Based on vue.js' camelize.
  camelize: (value) ->
    value.replace CAMELIZE_RE, (match, capture) ->
      if capture
        capture.toUpperCase()
      else
        ''

  # Hyphenate a camelCase string.
  # Based on vue.js' hyphenate.
  hyphenate: (value) ->
    value.replace(HYPHENATE_RE, '$1-$2').replace(HYPHENATE_RE, '$1-$2').toLowerCase()
