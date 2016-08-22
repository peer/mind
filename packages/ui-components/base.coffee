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

class UIMixin extends CommonMixin
  getFirstWith: (args...) ->
    @component().getFirstWith args...
