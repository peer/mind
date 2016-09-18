class UIComponent extends CommonComponent
  onRendered: ->
    super

    Tracker.afterFlush =>
      # This does not handle all cases, for example, if text changes reactively after
      # the component has been rendered, but "balance-text" class should be used on
      # simple text segments anyway, so it should work in practice.
      $.fn.balanceTextUpdate()

  storageUrl: (filename, kwargs) ->
    Storage.url filename

  isSandstorm: ->
    !!__meteor_runtime_config__.SANDSTORM

  $eq: (args...) ->
    # Removing kwargs.
    args.pop() if args[args.length - 1] instanceof Spacebars.kw

    first = args[0]
    for arg in args[1..] when not EJSON.equals first, arg
      return false

    true

  formatStartEndDate: (start, end, datetimeFormat, timeFormat) ->
    start = null if start instanceof Spacebars.kw
    end = null if end instanceof Spacebars.kw
    datetimeFormat = null if datetimeFormat instanceof Spacebars.kw
    timeFormat = null if timeFormat instanceof Spacebars.kw

    return null unless start

    start = moment start

    return @formatDate start, datetimeFormat unless end

    end = moment end

    # If end is on the same day as start, we use time formatting for end.
    if start.get('year') is end.get('year') and start.get('month') is end.get('month') and start.get('date') is end.get('date')
      endFormat = timeFormat
    else
      endFormat = datetimeFormat

    "#{@formatDate start, datetimeFormat} – #{@formatDate end, endFormat}"

  pluralize: (count, word) ->
    if count is 1
      "1 #{word}"
    else
      "#{count} #{word}s"

  # Converts an array of style classes into a class attribute. It doesn't return anything
  # if the array is empty (or null) so that class attribute is not unnecessarily created.
  # All input arrays are flattened and multiple input arrays can be passed. Everything
  # besides strings is filtered out.
  class: (styleClassesArrays...) ->
    # Removing kwargs.
    styleClassesArrays.pop() if styleClassesArrays[styleClassesArrays.length - 1] instanceof Spacebars.kw

    styleClassesArrays = _.uniq _.filter _.flatten(styleClassesArrays), (item) =>
      _.isString item
    if styleClassesArrays?.length
      class: styleClassesArrays.join ' '

  # Converts a style object to a css string. Useful in templates when you need just the string and not a style attribute.
  css: (styleObject...) ->
    # Removing kwargs.
    styleObject.pop() if styleObject[styleObject.length - 1] instanceof Spacebars.kw
    styleObject = _.filter styleObject, (x) -> !!x
    styleObject = _.extend {}, styleObject...

    propertyStrings = for camelCaseKey, value of styleObject
      key = camelCaseKey.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()

      # If a number was passed in, add the unit (except for certain CSS properties, as defined by jQuery)
      value += 'px' if typeof value is 'number' and not $.cssNumber[camelCaseKey]

      "#{key}: #{value};"

    propertyStrings.join ' '

  # Converts a style object to a css attribute. Useful in templates as a helper to construct the style attribute.
  style: (styleObject...) ->
    # Removing kwargs.
    styleObject.pop() if styleObject[styleObject.length - 1] instanceof Spacebars.kw
    styleObject = _.filter styleObject, (x) -> !!x
    styleObject = _.extend {}, styleObject...

    return if _.isEmpty styleObject

    style: @css styleObject

  descendantComponents: (args...) ->
    components = @childComponents args...

    for component in @childComponents()
      components = components.concat component.descendantComponents args...

    components

class UIMixin extends CommonMixin
  getFirstWith: (args...) ->
    @component().getFirstWith args...

  descendantComponents: (args...) ->
    @component().descendantComponents args...
