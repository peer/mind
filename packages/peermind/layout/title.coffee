share.PageTitle = new ReactiveField ''

Meteor.startup ->
  Tracker.autorun (computation) ->
    document.title = share.PageTitle()
