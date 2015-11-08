class EditorComponent extends UIComponent
  @register 'EditorComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'id', 'name', 'label'

  editor: ->
    @$('trix-editor').get(0)?.editor

  events: ->
    super.concat
      'trix-attachment-add': @onAttachmentAdd
      'click .select-file-link': @onSelectFileClick
      'change .select-file': @onSelectFileChange

  onAttachmentAdd: (event) ->
    attachment = event.originalEvent.attachment

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

class EditorComponent.Toolbar extends UIComponent
  @register 'EditorComponent.Toolbar'

  lang: ->
    Trix.config.lang

Trix.config.toolbar.content = Trix.makeFragment Blaze.toHTML EditorComponent.Toolbar.renderComponent()
