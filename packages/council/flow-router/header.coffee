class HeaderComponent extends UIComponent
  @register 'HeaderComponent'

  # Singleton-level title variable.
  @title: new ReactiveField ''

  title: ->
    @constructor.title()

  onRendered: ->
    super

    @$('.button-collapse').sideNav()

Meteor.startup ->
  Tracker.autorun (computation) ->
    document.title = HeaderComponent.title()
