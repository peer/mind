Meteor.startup ->
  $(document).on 'expandable.peermind', (event, expanding, data) ->
    # We store only when a feature is expanded.
    return unless expanding

    Meteor.call 'Activity.ui', 'expandable', data, (error, result) ->
      # We are ignoring errors.
