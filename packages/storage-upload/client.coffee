class UploadStatus
  constructor: ->
    # Current status or error message displayed to user.
    @status = new ReactiveField null
    # Progress of reading from file, in %.
    @readProgress = new ReactiveField 0
    # Progress of uploading file, in %.
    @uploadProgress = new ReactiveField 0

    @done = new ReactiveField null
    @error = new ReactiveField null

  # Fake update method for compatibility with MeteorFile.
  update: (id, modifier) ->
    @status modifier.$set.status
    @readProgress modifier.$set.readProgress
    @uploadProgress modifier.$set.uploadProgress

class StorageUpload extends StorageUpload
  @UPLOAD_CHUNK_SIZE = 128 * 1024 # bytes

  @uploadFile: (file) ->
    uploadStatus = new UploadStatus()

    meteorFile = new MeteorFile file,
      collection: uploadStatus

    meteorFile.upload file, 'Storage.upload',
      size: @UPLOAD_CHUNK_SIZE,
    ,
      (error, filename) =>
        if error
          uploadStatus.status "#{error}"
          uploadStatus.error error
          return

        uploadStatus.done filename

    uploadStatus

  @removeFile: (file, callback) ->
    meteorFile = new MeteorFile file

    Meteor.call 'Storage.remove', meteorFile, callback
