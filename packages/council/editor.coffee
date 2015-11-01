class EditorComponent extends UIComponent
  @register 'EditorComponent'

  constructor: (kwargs) ->
    super

    _.extend @, _.pick (kwargs?.hash or {}), 'id', 'name'

  events: ->
    super.concat
      'trix-attachment-add': @onAttachmentAdd
      'trix-attachment-remove': @onAttachmentRemove

  onAttachmentAdd: (event) ->
    attachment = event.originalEvent.attachment

    if attachment.attachment.documentId
      Meteor.call 'StorageFile.restore', attachment.attachment.documentId, (error) =>
        if error
          console.error "Restore attachment error", error
          alert "Restore attachment error: #{error.reason or error}"
          return

      return

    StorageFile.uploadFile attachment.file, (error, status) =>
      if error
        console.error "Add attachment error", error
        alert "Add attachment error: #{error.reason or error}"
        return

      # Store document ID so that we know which document to remove.
      attachment.attachment.documentId = status.documentId

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
          url: url
          href: href

  onAttachmentRemove: (event) ->
    attachment = event.originalEvent.attachment

    Meteor.call 'StorageFile.remove', attachment.attachment.documentId, (error) =>
      if error
        console.error "Remove attachment error", error
        alert "Remove attachment error: #{error.reason or error}"
        return

  attachmentsIds: ->
    (attachment.documentId for attachment in @$('trix-editor').get(0).editor.composition.getAttachments() when attachment.documentId)

class EditorComponent.Toolbar extends UIComponent
  @register 'EditorComponent.Toolbar'

  lang: ->
    Trix.config.lang

Trix.config.toolbar.content = Trix.makeFragment Blaze.toHTML EditorComponent.Toolbar.renderComponent()
