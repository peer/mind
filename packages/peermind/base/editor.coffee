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

  onRendered: ->
    super

    state = localStorage["editor.state.#{@id}"]

    return unless state

    # Restores any stored state.
    @editor()?.loadJSON JSON.parse state

    @active true if @hasContent()

  editor: ->
    @$('trix-editor').get(0)?.editor

  events: ->
    super.concat
      'trix-attachment-add': @onAttachmentAdd
      'click .select-file-link': @onSelectFileClick
      'change .select-file': @onSelectFileChange
      'trix-change': @onChange
      'trix-focus': @onFocus
      'trix-blur': @onBlur

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
  onChange: (event) ->
    editor = @editor()

    return unless editor

    localStorage["editor.state.#{@id}"] = JSON.stringify editor

  onFocus: (event) ->
    @focused true
    @active true

  onBlur: (event) ->
    @focused false
    @active false unless @hasContent()

  classes: ->
    classes = []
    classes.push 'focused' if @focused()
    classes.push 'active' if @active()
    classes

  hasContent: ->
    # Does editor has at least some text content or a figure?
    $body = $($.parseHTML(@$("##{@id}").val()))
    $body.text() or $body.has('figure').length

class EditorComponent.Toolbar extends UIComponent
  @register 'EditorComponent.Toolbar'

  lang: ->
    Trix.config.lang

Trix.config.toolbar.content = Trix.makeFragment Blaze.toHTML EditorComponent.Toolbar.renderComponent()

# Currently we prevent editing of captions of previewable attachments.
# TODO: Make previewable attachments' caption optional but still editable. See https://github.com/basecamp/trix/issues/87

originalCreateNodes = Trix.AttachmentView::createNodes
Trix.AttachmentView::createNodes = ->
  [cursorTarget1, element, cursorTarget2] = originalCreateNodes.call @

  if not @attachmentPiece.getCaption() and @attachment.isPreviewable()
    $element = $(element)
    $element.find('figcaption').remove()
    element = $element.get(0)

  [cursorTarget1, element, cursorTarget2]

originalMakeCaptionEditable = Trix.AttachmentEditorController::makeCaptionEditable
Trix.AttachmentEditorController::makeCaptionEditable = ->
  return if not @attachmentPiece.getCaption() and @attachment.isPreviewable()

  originalMakeCaptionEditable.call @
