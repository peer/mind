class Settings.DisplayComponent extends UIComponent
  @register 'Settings.DisplayComponent'

  onCreated: ->
    super

    @subscribe 'User.settings'

  onRendered: ->
    super

    @autorun (computation) =>
      return unless @hasAccess() and Accounts._loginServicesHandle.ready() and @subscriptionsReady()
      computation.stop()

      Tracker.afterFlush =>
        # TODO: We should reinitialize scrollSpy when position of elements changes.
        #       We could simply have an autorun observing any change to @currentUser() and reinitializing (maybe with debounce).
        #       See: https://github.com/Dogfalo/materialize/issues/3557
        @$('.scrollspy').scrollSpy
          scrollOffset: 100

        @$('.table-of-contents').pushpin
          top: @$('.table-of-contents').position().top

  hasAccess: ->
    !!@currentUserId()

  anyServiceConfiguration: ->
    ServiceConfiguration.configurations.find().exists()

class Settings.NameComponent extends UIComponent
  @register 'Settings.NameComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

  onSubmit: (event) ->
    event.preventDefault()

    Meteor.call 'Account.changeName', @$('[name="name"]').val(), (error) =>
      if error
        console.error "Change name error", error
        alert "Change name error: #{error.reason or error}"
        return

  name: ->
    Tracker.afterFlush =>
      # If value is set, we have to update fields to move the label to not overlap the value.
      Materialize.updateTextFields()

    @currentUser(name: 1)?.name or ''

class Settings.UsernameComponent extends UIComponent
  @register 'Settings.UsernameComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

  onSubmit: (event) ->
    event.preventDefault()

    Meteor.call 'Account.changeUsername', @$('[name="username"]').val(), (error) =>
      if error
        console.error "Change username error", error
        alert "Change username error: #{error.reason or error}"
        return

      event.target.reset()

  USERNAME_REGEX: ->
    Settings.USERNAME_REGEX

class Settings.PasswordComponent extends UIComponent
  @register 'Settings.PasswordComponent'

  onRendered: ->
    super

    Materialize.updateTextFields()

  onSubmit: (event) ->
    event.preventDefault()

    newPassword = @$('[name="new-password"]').val()
    confirmNewPassword = @$('[name="confirm-new-password"]').val()

    # Just to be sure. Form validation should catch this.
    unless newPassword is confirmNewPassword
      # TODO: Use flash messages.
      alert "Password do not match."
      return

    Accounts.changePassword @$('[name="old-password"]').val(), newPassword, (error) =>
      if error
        console.error "Change password error", error
        alert "Change password error: #{error.reason or error}"
        return

      event.target.reset()

  linkText: ->
    T9n.get AccountsTemplates.texts.pwdLink_link, markIfMissing: false

  onForgotPassword: (event) ->
    event.preventDefault()

    email = Meteor.user()?.emails[0].address
    unless email
      # TODO: Use flash messages.
      alert "E-mail address missing."
      return

    # TODO: We should probably first display a submit form button for confirmation.
    #       The same form as it is for the reset password form, just without the e-mail address input field.
    Accounts.forgotPassword email: email, (error) =>
      if error
        console.error "Forgot password error", error
        alert "Forgot password error: #{error.reason or error}"
        return

      alert "Reset password e-mail has been sent to '#{email}'."

class Settings.AccountsComponent extends UIComponent
  @register 'Settings.AccountsComponent'

  onLink: (event, serviceName) ->
    event.preventDefault()

    Meteor["loginWith#{_.capitalize serviceName}"]
      requestPermissions: Accounts.ui._options.requestPermissions[serviceName]
    ,
      (error) =>
        if error
          console.error "Linking with #{_.capitalize serviceName} error", error
          alert "Linking with #{_.capitalize serviceName} error: #{error.reason or error}"

  onUnlink: (event, serviceName) ->
    event.preventDefault()

    Meteor.call 'Account.unlinkAccount', serviceName, (error, result) =>
      if error
        console.error "Unlinking from #{_.capitalize serviceName} error", error
        alert "Unlinking from #{_.capitalize serviceName} error: #{error.reason or error}"

      # TODO: Should we check the result and if it is not expected show an error instead?

class Settings.AvatarComponent extends UIComponent
  @register 'Settings.AvatarComponent'

  onSelect: (event, name, argument) ->
    event.preventDefault()

    Meteor.call 'Account.selectAvatar', name, (argument or null), (error, result) =>
      if error
        console.error "Selecting avatar error", error
        alert "Selecting avatar error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

class Settings.ResearchDataComponent extends UIComponent
  @register 'Settings.ResearchDataComponent'

  constructor: (kwargs) ->
    super

    @isSettings = !!kwargs?.hash?.isSettings

  checked: (value) ->
    return unless @isSettings

    if @currentUser()?.researchData
      return checked: true if value is 'yes'
    else if @currentUser()?.researchData?
      return checked: true if value is 'no'

  onChange: (event) ->
    return unless @isSettings

    event.preventDefault()

    consent = @$('[name="research-data"]:checked').val()

    return unless consent

    Meteor.call 'Account.researchData', consent is 'yes', (error, result) =>
      if error
        console.error "Setting research data error", error
        alert "Setting research data error: #{error.reason or error}"

        # TODO: This should set it to old value, which is not necessary that no radio button was selected.
        @$('[name="research-data"]').prop('checked', false)

      # TODO: Should we check the result and if it is not expected show an error instead?

class Settings.DelegationsComponent extends UIComponent
  @register 'Settings.DelegationsComponent'

  onCreated: ->
    super

    @changingRatioUserId = new ReactiveField null
    @changingRatioValue = new ReactiveField null

    @currentDelegationsLength = new ComputedField =>
      @currentDelegations().length

    @usersHandle = @subscribe 'User.list'

  onRendered: ->
    super

    @autorun (computation) =>
      @currentDelegationsLength()

      # When length changes, delegationsEquation changes, so we should update balance text.
      $.fn.balanceTextUpdate()

  events: ->
    super.concat
      'slide .range': @onRangeSlide
      'slidestop .range, click .range': @onRangeSlideStop

  currentDelegations: ->
    delegations = @currentUser(delegations: 1)?.delegations or []

    # We first normalize all ratios so that the sum is 1.0. We normalize because this is what is done when delegated
    # votes are computed. It can happen that an user who was a delegate and was deleted and removed from the list of
    # delegations. As a consequence, the list of delegations does not contain correctly normalized ratios anymore.
    # TODO: Should we inform user that one of their delegates were deleted?
    # TODO: Should we recompute ratios in the database when one of users who are delegates are deleted?
    delegations = User.normalizeDelegations delegations

    # Now we apply any temporary override we might have while a user is changing a ratio.
    if @changingRatioUserId() and @changingRatioValue()?
      delegations = User.setDelegations delegations, @changingRatioUserId(), @changingRatioValue()

    delegations

  delegationsEquation: ->
    # \u00A0 is a non-breaking space.
    parts = ("#{delegation.ratio.toFixed 2}\u00A0×\u00A0vote\u00A0by\u00A0#{delegation.user.username}"for delegation in @currentDelegations())

    parts.join " + "

  onRangeSlideStop: (event, ui) ->
    @changingRatioUserId null
    @changingRatioValue null

    Meteor.call 'User.setDelegation', @currentComponent().data('user._id'), parseFloat(@currentComponent().$('.range').slider('value')), (error, result) =>
      if error
        console.error "Set delegation error", error
        alert "Set delegation error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

  onRangeSlide: (event, ui) ->
    @changingRatioUserId @currentComponent().data 'user._id'
    @changingRatioValue parseFloat(ui.value)

  users: ->
    currentDelegationsIds = (delegation.user._id for delegation in @currentDelegations() when delegation?.user?._id)

    User.documents.find _.extend(@usersHandle.scopeQuery(),
      _id:
        $nin: [@currentUserId()].concat currentDelegationsIds
    ),
      sort:
        # TODO: Sort by filter quality.
        username: 1

class Settings.DelegationsItemComponent extends UIComponent
  @register 'Settings.DelegationsItemComponent'

  currentDelegationsLength: ->
    @callAncestorWith 'currentDelegationsLength'

  onRemove: (event) ->
    event.preventDefault()

    Meteor.call 'User.removeDelegation', @data('user._id'), (error, result) =>
      if error
        console.error "Remove delegation error", error
        alert "Remove delegation error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

class Settings.DelegationsRangeComponent extends UIComponent
  @register 'Settings.DelegationsRangeComponent'

  onRendered: ->
    super

    @$('.range').slider
      range: 'min'
      min: 0.0
      max: 1.0
      step: 0.01
      value: @data('ratio') ? 0.0
      slide: (event, ui) =>
        @$('.ui-slider-handle').text(ui.value)
        return
      change: (event, ui) =>
        @$('.ui-slider-handle').text(ui.value)
        return

    @autorun (computation) =>
      value = @data('ratio') ? 0.0

      @$('.range').slider('value', value)

class Settings.DelegationsUserComponent extends UIComponent
  @register 'Settings.DelegationsUserComponent'

  onSelect: (event) ->
    event.preventDefault()

    Meteor.call 'User.addDelegation', @data('_id'), (error, result) =>
      if error
        console.error "Add delegation error", error
        alert "Add delegation error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

FlowRouter.route '/account/settings',
  name: 'Settings.display'
  action: (params, queryParams) ->
    BlazeLayout.render 'MainLayoutComponent',
      main: 'Settings.DisplayComponent'

    share.PageTitle "Settings"
