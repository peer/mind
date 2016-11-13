class User.DisplayComponent extends UIComponent
  @register 'User.DisplayComponent'

  mixins: ->
    super.concat share.EditableMixin

  onCreated: ->
    super

    @currentUserId = new ComputedField =>
      FlowRouter.getParam '_id'

    @autorun (computation) =>
      userId = @currentUserId()
      @subscribe 'User.profile', userId if userId

    @autorun (computation) =>
      return unless @subscriptionsReady()

      user = User.documents.findOne @currentUserId(),
        fields:
          username: 1

      if user
        share.PageTitle user.username
      else
        share.PageTitle "Not found"

    @canEdit = new ComputedField =>
      @user() and Meteor.userId() and Meteor.userId() is @user()._id

  user: ->
    User.documents.findOne @currentUserId()

  notFound: ->
    @subscriptionsReady() and not @user()

  onSaveEdit: (event, onSuccess) ->
    Meteor.call 'User.profileUpdate', @$('[name="profile"]').val(), (error, result) =>
      if error
        console.error "Update profile error", error
        alert "Update profile error: #{error.reason or error}"
        return

      # TODO: Should we check the result and if it is not expected show an error instead?

      onSuccess()

  # TODO: Should we populate the list with user's friends or something like this?
  contributeUsersForMention: ->
    []
