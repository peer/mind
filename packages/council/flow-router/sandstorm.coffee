if __meteor_runtime_config__.SANDSTORM
  # Since the Sandstorm grain is displayed in an iframe of the Sandstorm shell,
  # we need to explicitly expose meta data like the page title or the URL path
  # so that they could appear in the browser window.
  # See https://docs.sandstorm.io/en/latest/developing/path/
  updateSandstormMetaData = (message) ->
    window.parent?.postMessage message, '*'

  FlowRouter.triggers.enter ({path}) ->
    updateSandstormMetaData
      setPath: path

  Meteor.startup ->
    Tracker.autorun (computation) ->
      updateSandstormMetaData
        setTitle: share.PageTitle()
