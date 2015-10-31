class Storage
  @DEFAULT_STORAGE_PATH: '/storage'

  @initialize: (@options={}) ->

    @options = _.defaults {}, @options,
      storagePath: @DEFAULT_STORAGE_PATH

  @url: (filename) ->
    "#{@options.storagePath}/" + filename

  # Client version, on server it is overridden with system's.
  @_path:
    sep: '/'
