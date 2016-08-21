Meteor.startup ->
  $(document).on 'expandable.peermind', (event, expanding, data) ->
    # We store only when a feature is expanded.
    return unless expanding

    Meteor.apply 'Activity.ui', ['expandable', data], {noRetry: true}, (error, result) ->
      # We are ignoring errors.
