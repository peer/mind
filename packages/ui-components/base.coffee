class UIComponent extends CommonComponent
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
    styleClassesArrays = _.uniq _.filter _.flatten(styleClassesArrays), (item) =>
      _.isString item
    if styleClassesArrays?.length
      class: styleClassesArrays.join ' '

class UIMixin extends CommonMixin
  getFirstWith: (args...) ->
    @component().getFirstWith args...
