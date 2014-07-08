Express middleware to build and serve on demand.

    parseurl = require 'parseurl'
    async = require 'async'
    path = require 'path'
    builder = require './builder.litcoffee'

    module.exports = (args, directory) ->
      (req, res, next) ->
        if 'GET' isnt req.method and 'HEAD' isnt req.method
          return next()
        filename = path.join directory or process.cwd(), parseurl(req).pathname

For path references, assume index.html

        if '/' == filename[filename.length - 1]
          filename += 'index.html'

        if path.extname(filename) isnt '.html'
          return next()
        builder(args or {}) filename, (e, content) ->
          if e
            res.statusCode = 500
            res.end "#{e}"
          else
            res.statusCode = 200
            res.end content
