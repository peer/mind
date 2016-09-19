class EditorComponent extends UIComponent
  @register 'EditorComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'id', 'name', 'label', 'autofocus'

    throw new Error "Missing 'id'." unless @id
    throw new Error "Missing 'name'." unless @name

  onCreated: ->
    super

    @active = new ReactiveField false
    @focused = new ReactiveField false

    @mentionPosition = new ReactiveField null, EJSON.equals
    @mentionAtPosition = new ReactiveField null, true
    @mentionContent = new ReactiveField ''
    @mentionHandle = new ReactiveField null
    @mentionSelected = new ReactiveField null

    @mentionDialogUsersCount = new ComputedField =>
      users = @mentionDialogUsers()
      if _.isArray users
        return users.length
      else
        return users.count()

  onRendered: ->
    super

    state = localStorage["editor.state.#{@id}"]

    # Restores any stored state.
    @editor()?.loadJSON JSON.parse state if state

    @active true if @hasContent()

    # Every time mentionAtPosition is set to null, we try to finish previous mention.
    @autorun (computation) =>
      return unless @mentionAtPosition() is null

      # Should not really happen.
      return if @mentionAtPosition.previous() is null

      @finishMention @mentionAtPosition.previous()

    @autorun (computation) =>
      return if @mentionSelected() is null

      if @mentionSelected() < 0
        @mentionSelected 0

      else
        usersCount = @mentionDialogUsersCount()

        unless usersCount
          @mentionSelected 0
        else if @mentionSelected() > usersCount - 1
          @mentionSelected usersCount - 1

    @autorun (computation) =>
      return if @mentionSelected() is null

      Tracker.nonreactive =>
        Tracker.afterFlush =>
          return if @mentionSelected() is null or @mentionSelected() < 0 or @mentionSelected() > @mentionDialogUsersCount() - 1

          $mentionToBeVisible = @$('.mention li').eq(@mentionSelected())

          return unless $mentionToBeVisible.length

          $offsetParent = $mentionToBeVisible.offsetParent()

          offsetParentTop = $offsetParent.scrollTop()
          offsetParentBottom = $offsetParent.height() + offsetParentTop
          mentionTop = $mentionToBeVisible.position().top + $offsetParent.scrollTop()
          mentionBottom = mentionTop + $mentionToBeVisible.height()

          # Mention is fully visible.
          return if mentionTop >= offsetParentTop && mentionBottom <= offsetParentBottom

          # If top is closer.
          if Math.abs(offsetParentTop - mentionTop) < Math.abs(offsetParentBottom - mentionBottom)
            $offsetParent.scrollTop $offsetParent.scrollTop() - Math.abs(offsetParentTop - mentionTop)
          else
            $offsetParent.scrollTop $offsetParent.scrollTop() + Math.abs(offsetParentBottom - mentionBottom)

    @autorun (computation) =>
      unless @mentionContent()
        @mentionHandle null
        return

      @mentionHandle @subscribe 'User.autocomplete', @mentionContent()

  editor: ->
    return null unless @isRendered()

    @$('trix-editor').get(0)?.editor

  events: ->
    super.concat
      'trix-attachment-add': @onAttachmentAdd
      'click .select-file-link': @onSelectFileClick
      'change .select-file': @onSelectFileChange
      'trix-focus': @onFocus
      'trix-blur': @onBlur
      'trix-change': @storeEditorState
      'trix-selection-change, trix-focus, trix-change': @doMention
      'keydown trix-editor': @onKeyDown

  onAttachmentAdd: (event) ->
    attachment = event.originalEvent.attachment

    # Return of an already processes attachment (e.g., this happens on redo).
    if attachment.getAttribute 'documentId'
      return

    else if attachment.file
      StorageFile.uploadFile attachment.file, (error, status) =>
        if error
          console.error "Add attachment error", error
          alert "Add attachment error: #{error.reason or error}"
          return

        @autorun (computation) =>
          attachment.setUploadProgress status.uploadProgress()

        @autorun (computation) =>
          return unless status.done() or status.error()
          computation.stop()

          if error = status.error()
            console.error "Add attachment error", error
            alert "Add attachment error: #{error.reason or error}"
            return

          assert status.done()

          url = href = Storage.url status.filename

          attachment.setAttributes
            href: href
            type: 'file'
            documentId: status.documentId

          if attachment.isPreviewable()
            attachment.setAttributes
              url: url

    else
      console.error "Attachment without documentId error", attachment
      alert "Attachment without documentId error."

  onSelectFileClick: (event) ->
    event.preventDefault()

    @$('.select-file').click()

  onSelectFileChange: (event) ->
    event.preventDefault()

    return if event.target.files?.length is 0

    for file in event.target.files
      @editor().insertFile file

    # Replaces file input with a new version which does not have any file selected. This assures that change event
    # is triggered even if the user selects the same file. It is not really reasonable to do that, but it is still
    # better that we do something than simply nothing because no event is triggered.
    $(event.target).replaceWith($(event.target).clone())

  value: ->
    @data()?[@name] or ''

  reset: ->
    delete localStorage["editor.state.#{@id}"]
    @active false

  # Store editor state to local storage on every change to support resuming editing if interrupted by any reason.
  storeEditorState: (event) ->
    editor = @editor()

    return unless editor

    localStorage["editor.state.#{@id}"] = JSON.stringify editor

  onFocus: (event) ->
    @focused true
    @active true

  onBlur: (event) ->
    @focused false
    @active false unless @hasContent()

    @disableMention()

  classes: ->
    classes = []
    classes.push 'focused' if @focused()
    classes.push 'active' if @active()
    classes

  hasContent: ->
    # Does editor has at least some text content or a figure?
    $body = $($.parseHTML(@$("##{@id}").val()))
    $body.text() or $body.has('figure').length

  disableMention: ->
    @mentionPosition null
    @mentionAtPosition null
    @mentionContent ''
    @mentionSelected null

  doMention: (event) ->
    editor = @editor()

    return unless editor

    position = editor.getPosition()
    documentString = editor.getDocument().toString()

    beforePosition = documentString.substring 0, position

    # Based on Settings.USERNAME_REGEX.
    match = /(@[A-Za-z0-9_]*)$/.exec beforePosition

    if match
      atPosition = position - match[1].length
      afterAtPosition = documentString.substring atPosition + 1
      # Based on Settings.USERNAME_REGEX.
      mentionContentMatch = /^([A-Za-z0-9_]*)/.exec afterAtPosition

      cursorPosition = editor.getClientRectAtPosition atPosition
      # Sometimes getClientRectAtPosition returns undefined. In that case we retry later.
      unless cursorPosition
        Tracker.afterFlush =>
          @doMention event
        return

      @mentionPosition _.pick cursorPosition, 'left', 'bottom'
      @mentionAtPosition atPosition
      @mentionContent mentionContentMatch[1]
      @mentionSelected 0 if @mentionSelected() is null
    else
      @disableMention()

  mentionDialogPosition: ->
    position = @mentionPosition()
    return unless position

    # .editor-wrapper is an offset parent, it has position: relative.
    offsetParentOffset = @$('.editor-wrapper').offset()

    viewportPositionTop = position.bottom
    viewportPositionLeft = position.left

    # We convert document-based offset values to viewport-based by subtracting scrolling.
    top: viewportPositionTop - (offsetParentOffset.top - $(window).scrollTop())
    left: viewportPositionLeft - (offsetParentOffset.left - $(window).scrollLeft())

  mentionDialogUsers: ->
    handle = @mentionHandle()
    return [] unless handle

    User.documents.find handle.scopeQuery(),
      sort:
        username: 1

  splitMention: (username) ->
    username.split new RegExp("^(#{@mentionContent()})", 'i')

  matchingMention: (username) ->
    split = @splitMention username

    if split.length > 1
      # If there was a split, then split contains ["", <matching mention>, <nonmatching mention>].
      split[1]
    else
      ''

  nonmatchingMention: (username) ->
    split = @splitMention username

    if split.length > 1
      # If there was a split, then split contains ["", <matching mention>, <nonmatching mention>].
      split[2]
    else
      split[0]

  onKeyDown: (event) ->
    editor = @editor()

    return unless editor

    return unless @mentionPosition()

    return if event.shiftKey or event.altKey or event.ctrlKey or event.metaKey

    # Escape key.
    if event.which is 27
      event.preventDefault()
      @disableMention()
      return

    return unless @mentionDialogUsersCount()

    # Down key.
    if event.which is 40
      event.preventDefault()
      @mentionSelected @mentionSelected() + 1 if @mentionSelected() isnt null

    # Up key.
    else if event.which is 38
      event.preventDefault()
      @mentionSelected @mentionSelected() - 1 if @mentionSelected() isnt null and @mentionSelected() > 0

    # Return key.
    # Any conditions which allow this code to run should be matched
    # in our Trix.InputController::keys.return monkey-patched method.
    # TODO: Should we also do it for tab key?
    else if event.which is 13
      event.preventDefault()

      $mentionToBeSelected = @$('.mention li').eq(@mentionSelected())

      return unless $mentionToBeSelected.length

      dataContext = Blaze.getData $mentionToBeSelected.get(0)

      return unless dataContext

      position = editor.getPosition()
      editor.setSelectedRange [@mentionAtPosition() + 1, position]
      editor.deleteInDirection 'forward'
      editor.insertString dataContext.username

      @finishMention @mentionAtPosition(), editor.getPosition()

  finishMention: (atPosition, endPosition) ->
    editor = @editor()

    return unless editor

    documentString = editor.getDocument().toString()

    # If endPosition is null, it will return the string to the end
    # and then regex will match a reasonable username.
    afterAtPosition = documentString.substring atPosition, endPosition
    # Based on Settings.USERNAME_REGEX.
    mentionContentMatch = /^@([A-Za-z0-9_]+)/.exec afterAtPosition

    if mentionContentMatch
      username = mentionContentMatch[1]
      # We assume that the user with this username is published to the client.
      user = User.documents.findOne
        username: username

      if user
        embed = EditorComponent.Mention.renderComponentToHTML(null, null, user).trim()
        attachment = new Trix.Attachment
          content: embed
          type: 'mention'
          documentId: user._id

        mentionEndPosition = atPosition + username.length + 1
        oldSelection = editor.getSelectedRange()

        # If an edge of an existing selection is inside the mention, move it to the end.
        for selection, i in oldSelection when selection > atPosition and selection < mentionEndPosition
          oldSelection[i] = mentionEndPosition

        editor.setSelectedRange [atPosition, mentionEndPosition]
        editor.deleteInDirection 'forward'
        editor.insertAttachment attachment

        endPositionAfterInsert = editor.getPosition()

        # If an edge is after the inserted mention, adapt it to the new size of the mention content.
        # We changed oldSelection's edges can be only before or after the inserted mention
        # and we have to adapt only edges after.
        for selection, i in oldSelection when selection >= mentionEndPosition
          oldSelection[i] = selection + (endPositionAfterInsert - mentionEndPosition)

        # Restore selection from before we inserted the mention.
        editor.setSelectedRange oldSelection

    @disableMention()

class EditorComponent.Toolbar extends UIComponent
  @register 'EditorComponent.Toolbar'

  lang: ->
    Trix.config.lang

class EditorComponent.Mention extends UIComponent
  @register 'EditorComponent.Mention'

Trix.config.toolbar.content = Trix.makeFragment EditorComponent.Toolbar.renderComponentToHTML()

originalReturn = Trix.InputController::keys.return
Trix.InputController::keys.return = (event) ->
  editorComponent = UIComponent.getComponentForElement @element

  # These conditions are the same as onKeyDown conditions which allow its
  # return key case to run. We should return here always when that case runs.
  if editorComponent and not (event.shiftKey or event.altKey or event.ctrlKey or event.metaKey) and editorComponent.editor() and editorComponent.mentionPosition() and editorComponent.mentionDialogUsersCount()
    return

  originalReturn.call @, event

# Currently we prevent editing of captions of previewable attachments or those with content.
# TODO: Make previewable attachments' caption optional but still editable. See https://github.com/basecamp/trix/issues/87

originalCreateNodes = Trix.AttachmentView::createNodes
Trix.AttachmentView::createNodes = ->
  [cursorTarget1, element, cursorTarget2] = originalCreateNodes.call @

  if not @attachmentPiece.getCaption() and (@attachment.isPreviewable() or @attachment.hasContent())
    $element = $(element)
    $element.find('figcaption').remove()
    element = $element.get(0)

  [cursorTarget1, element, cursorTarget2]

originalMakeCaptionEditable = Trix.AttachmentEditorController::makeCaptionEditable
Trix.AttachmentEditorController::makeCaptionEditable = ->
  return if not @attachmentPiece.getCaption() and (@attachment.isPreviewable() or @attachment.hasContent())

  originalMakeCaptionEditable.call @
