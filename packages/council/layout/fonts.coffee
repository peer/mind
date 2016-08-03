# A workaround for invalid fonts URLs in materialize package.
# See: https://github.com/Dogfalo/materialize/issues/3413
WebApp.connectHandlers.use '/packages/materialize_materialize/fonts', (req, res) ->
  url = req.originalUrl.replace '/fonts/', '/dist/fonts/'
  res.statusCode = 301
  res.setHeader 'Location', url
  res.end()
