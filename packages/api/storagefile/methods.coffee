mime = Npm.require 'mime-types'

Meteor.methods
  'StorageFile.new': (file) ->
    check file,
      name: Match.OptionalOrNull String
      type: Match.OptionalOrNull String
      # TODO: Limit maximum file size?
      size: Match.Where (x) ->
        check x, Number
        x >= 0

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    originalFilename = file.name or null
    mimeType = file.type or null

    if originalFilename
      sanitizedFilename = originalFilename.replace(/\//g, '').replace(/\.\.+/g, '.').replace(/\x00/g, '')
      # We expect filename extension to be reasonable for the provided MIME type.
      filename = "#{Random.id()}/#{sanitizedFilename}"
    else if mimeType and extension = mime.extension mimeType
      filename = "#{Random.id()}.#{extension}"
    else
      filename = Random.id()

    filename = "upload/#{filename}"

    createdAt = new Date()
    documentId = StorageFile.documents.insert
      createdAt: createdAt
      updatedAt: createdAt
      author:
        _id: userId
      filename: filename
      originalFilename: originalFilename
      mimeType: mimeType
      size: file.size
      done: false
      active: false

    assert documentId

    {documentId, filename}

  'StorageFile.upload': (file, options) ->
    check file, MeteorFile
    check options,
      documentId: Match.DocumentId

    userId = Meteor.userId()
    throw new Meteor.Error 'unauthorized', "Unauthorized." unless userId

    storageFile = StorageFile.documents.findOne
      _id: options.documentId
      'author._id': userId
    ,
      fields:
        filename: 1
        size: 1

    throw new Meteor.Error 'not-found', "Storage file '#{options.documentId}' cannot be found." unless storageFile

    throw new Meteor.Error 'invalid-request', "Invalid file." unless file.size is storageFile.size
    throw new Meteor.Error 'invalid-request', "Invalid file." unless file.start + file.data.length is file.end
    throw new Meteor.Error 'invalid-request', "Invalid file." unless file.start + file.data.length <= file.size
    throw new Meteor.Error 'invalid-request', "Invalid file." unless file.data.length is StorageFile.UPLOAD_CHUNK_SIZE or (file.data.length < StorageFile.UPLOAD_CHUNK_SIZE and file.start + StorageFile.UPLOAD_CHUNK_SIZE > file.size)

    Storage.saveMeteorFile file, storageFile.filename

    updatedAt = new Date()

    # File has finished uploading.
    if file.end is file.size
      StorageFile.documents.update
        _id: options.documentId
      ,
        $set:
          done: true
          updatedAt: updatedAt

    else
      StorageFile.documents.update
        _id: options.documentId
      ,
        $set:
          updatedAt: updatedAt

    return
