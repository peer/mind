Meteor.startup ->
  focused = document.hasFocus()

  focusChange = (event) ->
    return if focused is document.hasFocus()
    focused = document.hasFocus()

    Meteor.call 'Activity.focus', focused, (error, result) ->
      # We are ignoring errors.

  debouncedFocusChange = _.debounce focusChange, 5000 # ms

  $(document).on 'focus', debouncedFocusChange
  $(document).on 'blur', debouncedFocusChange

  $(window).on 'focus', debouncedFocusChange
  $(window).on 'blur', debouncedFocusChange
