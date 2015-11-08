class EditorComponent extends UIComponent
  @register 'EditorComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'id', 'name', 'label'

  events: ->
    super.concat
      'trix-attachment-add': @onAttachmentAdd

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

class EditorComponent.Toolbar extends UIComponent
  @register 'EditorComponent.Toolbar'

  lang: ->
    Trix.config.lang

Trix.config.toolbar.content = Trix.makeFragment Blaze.toHTML EditorComponent.Toolbar.renderComponent()
