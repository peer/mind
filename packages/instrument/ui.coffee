Meteor.startup ->
  $(document).on 'expandable.peermind', (event, expanding, documentType, document) ->
    # We store only when a feature is expanded.
    return unless expanding

    Meteor.apply 'Activity.ui', ['expandable', documentType, document], {noRetry: true}, (error, result) ->
      # We are ignoring errors.
