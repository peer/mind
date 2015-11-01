Fiber = Npm.require 'fibers'
fs = Npm.require 'fs'
pathModule = Npm.require 'path'
url = Npm.require 'url'

# From Meteor's random/random.js.
UNMISTAKABLE_CHARS = '23456789ABCDEFGHJKLMNPQRSTWXYZabcdefghijkmnopqrstuvwxyz'

NON_ASCII_REGEX = /[^\x20-\x7E]/
CACHE_ID_REGEX = new RegExp "^/([#{UNMISTAKABLE_CHARS}]{17})\\.(\\w+)$"

class Storage extends Storage
  @DEFAULT_MAX_AGE: 24 * 60 * 60 * 1000 # ms

  @initialize: (@options={}) ->
    super

    @options = _.defaults {}, @options,
      maxAge: @DEFAULT_MAX_AGE

    @_determineStorageDirectory()
    @_serveFiles()

  @_determineStorageDirectory: ->
    return if @options.storageDirectory

    if process.env.STORAGE_DIRECTORY
      @options.storageDirectory = process.env.STORAGE_DIRECTORY
    else
      # Find .meteor directory.
      directoryPath = process.mainModule.filename.split pathModule.sep
      while directoryPath.length > 0
        if directoryPath[directoryPath.length - 1] == '.meteor'
          break
        directoryPath.pop()

      assert directoryPath.length > 0

      directoryPath.push 'storage'
      @options.storageDirectory = directoryPath.join pathModule.sep

  @_serveFiles: ->
    # TODO: What about security? If ../.. are passed in?
    # TODO: Currently, if there is no file, processing is passed further and Meteor return 200 content, we should return 404 for these files.
    # TODO: Add CORS headers.
    # TODO: We have redirect == false because directory redirects do not take prefix into the account.
    WebApp.connectHandlers.use @options.storagePath, connect.static(@options.storageDirectory, {maxAge: @options.maxAge, redirect: false})
    WebApp.connectHandlers.use @options.storagePath, (req, res, next) =>
      res.statusCode = 404
      # TODO: Use our own 404 content, matching the 404 shown by nginx/reverse proxy.
      res.end '404 Not Found', 'utf8'

  @_assurePath: (path) ->
    path = path.split @_path.sep
    for segment, i in path[1...path.length - 1]
      p = path[0..i + 1].join @_path.sep
      if !fs.existsSync p
        fs.mkdirSync p

  @_assurePathAsync: (path, callback) ->
    path = path.split @_path.sep
    i = 0
    async.eachSeries path[1...path.length - 1], (segment, callback) =>
      i++
      p = path[0..i].join @_path.sep
      fs.exists p, (exists) =>
        return callback null if exists
        fs.mkdir p, callback
    ,
      callback

  @_fullPath: (filename) ->
    assert filename
    "#{@options.storageDirectory}#{@_path.sep}#{filename}"

  @save: (filename, data) ->
    path = @_fullPath filename
    @_assurePath path
    fs.writeFileSync path, data

    return

  @saveStreamAsync: (filename, stream, callback) ->
    stream.pause()

    path = @_fullPath filename
    @_assurePathAsync path, (error) =>
      return callback error if error

      finished = false
      stream.on('error', (error) =>
        return if finished
        finished = true
        callback error
      ).pipe(
        fs.createWriteStream path
      ).on('finish', =>
        return if finished
        finished = true
        callback null
      ).on('error', (error) =>
        return if finished
        finished = true
        callback error
      )

      stream.resume()

  @saveStream: blocking(@, @saveStreamAsync)

  @saveMeteorFile: (meteorFile, filename) ->
    path = @_fullPath filename
    directory = path.split('/').slice(0, -1).join('/')
    meteorFile.name = filename.split('/').slice(-1)[0]
    @_assurePath path
    meteorFile.save directory, {}

    return

  @exists: (filename) ->
    fs.existsSync @_fullPath filename

  @open: (filename) ->
    fs.readFileSync @_fullPath filename

  @rename: (oldFilename, newFilename) ->
    newPath = @_fullPath newFilename
    @_assurePath newPath
    fs.renameSync @_fullPath(oldFilename), newPath

    return

  @link: (existingFilename, newFilename) ->
    newPath = @_fullPath newFilename
    @_assurePath newPath
    existingPath = @_fullPath existingFilename
    fs.symlinkSync @_path.relative(@_path.dirname(newPath), existingPath), newPath

    return

  @remove: (filename) ->
    fs.unlinkSync @_fullPath filename

    return

  @lastModificationTime: (filename) ->
    stats = fs.statSync @_fullPath filename
    stats.mtime

# To be available if needed.
Storage._path = pathModule
