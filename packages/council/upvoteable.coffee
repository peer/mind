class UpvoteableButton extends UIComponent
  @register 'UpvoteableButton'

  onCreated: ->
    super

    @canUpvote = new ComputedField =>
      'upvote' if @data() and User.hasPermission(User.PERMISSIONS.UPVOTE) and Meteor.userId() isnt @data().author._id and Meteor.userId() not in _.pluck(_.pluck(@data().upvotes or [], 'author'), '_id')

    @canRemoveUpvote = new ComputedField =>
      'remove-upvote' if @data() and Meteor.userId() and Meteor.userId() isnt @data().author._id and Meteor.userId() in _.pluck(_.pluck(@data().upvotes or [], 'author'), '_id')

  upvoteTitle: ->
    return if @canUpvote() or @canRemoveUpvote()

    return title: "Sign in to upvote." unless Meteor.userId()

    if Meteor.userId() is @data().author._id
      title: "You cannot upvote your #{@data().verboseName()}."
    else
      title: "You cannot upvote this #{@data().verboseName()}."

  onButtonClick: (event) ->
    event.preventDefault()

    if @canUpvote()
      @upvote()
    else if @canRemoveUpvote()
      @removeUpvote()

  upvote: ->
    Meteor.call "#{@data().methodPrefix()}.upvote", @data()._id, (error, result) =>
      if error
        console.error "Upvote error", error
        alert "Upvote error: #{error.reason or error}"
        return

  removeUpvote: ->
    Meteor.call "#{@data().methodPrefix()}.removeUpvote", @data()._id, (error, result) =>
      if error
        console.error "Remove upvote error", error
        alert "Remove upvote error: #{error.reason or error}"
        return
