# Based on: https://stereologics.com/2015/04/02/about-page-visibility-api-hidden-visibilitychange-visibilitystate/

BROWSER_PREFIXES = [
  'moz'
  'ms'
  'o'
  'webkit'
]

getHiddenPropertyName = (prefix) ->
  if prefix then "#{prefix}Hidden" else 'hidden'

getVisibilityEvent = (prefix) ->
  "#{prefix or ''}visibilitychange"

getBrowserPrefix = ->
  for prefix in BROWSER_PREFIXES
    return prefix if getHiddenPropertyName(prefix) of document

  null

Meteor.startup ->
  browserPrefix = getBrowserPrefix()
  hiddenPropertyName = getHiddenPropertyName browserPrefix
  visibilityEventName = getVisibilityEvent browserPrefix

  # Maybe it is not supported.
  return unless hiddenPropertyName of document

  hidden = document[hiddenPropertyName]

  visibilityChange = (event) ->
    return if hidden is document[hiddenPropertyName]
    hidden = document[hiddenPropertyName]

    Meteor.call 'Activity.visibility', !hidden, (error, result) ->
      # We are ignoring errors.

  $(document).on visibilityEventName, _.debounce visibilityChange, 5000 # ms
