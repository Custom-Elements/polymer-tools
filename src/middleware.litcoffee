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
        if path.extname(filename) isnt '.html'
          return next()
        builder(args or {}) filename, (e, content) ->
          if e
            res.statusCode = 500
            res.end "#{e}"
          else
            res.statusCode = 200
            res.end content
