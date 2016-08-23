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

class UIMixin extends CommonMixin
  getFirstWith: (args...) ->
    @component().getFirstWith args...
