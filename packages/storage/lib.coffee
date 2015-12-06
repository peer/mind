class Storage
  @DEFAULT_STORAGE_PATH: '/storage'

  @initialize: (@options={}) ->

    @options = _.defaults {}, @options,
      storagePath: @DEFAULT_STORAGE_PATH

    # If flow router is in use and there is support for ignoring paths, we register storage path for
    # ignoring so that links to stored files are not intercepted by flow router by go to the server.
    FlowRouter = Package['peerlibrary:flow-router']?.FlowRouter
    if FlowRouter and FlowRouter.ignore
      FlowRouter.ignore @options.storagePath

  @url: (filename) ->
    "#{@options.storagePath}/#{filename}"

  # Client version, on server it is overridden with system's.
  @_path:
    sep: '/'
