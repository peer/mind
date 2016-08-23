try
  # We try to import the file. It should be generated during the build process,
  # exporting the version of the app (like git commit hash).
  __meteor_runtime_config__.VERSION = require './gitversion.coffee'

  # If it is an empty string, set it to null.
  __meteor_runtime_config__.VERSION ||= null
catch error
  # We are ignoring the error.
  __meteor_runtime_config__.VERSION = null
