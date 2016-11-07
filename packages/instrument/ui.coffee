Meteor.startup ->
  $(document).on 'expandable.peermind', (event, expanding, documentType, document) ->
    # We store only when a feature is expanded.
    return unless expanding

    Meteor.apply 'Activity.ui', ['expandable', documentType, document], {noRetry: true}, (error, result) ->
      # We are ignoring errors.

  $(document).on 'dropdown:open', (event) ->
    return unless $(event.target).is('.notifications-menu-button')

    Meteor.apply 'Activity.notifications', [], {noRetry: true}, (error, result) ->
      # We are ignoring errors.
