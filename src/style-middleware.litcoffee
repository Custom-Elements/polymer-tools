Express middleware to build and serve on demand.

    parseurl = require 'parseurl'
    less = require 'less'
    path = require 'path'
    fs = require 'fs'
    Promise = require 'bluebird'

    Promise.promisifyAll fs
    Promise.promisifyAll less

    module.exports = (args, directory) ->
      (req, res, next) ->
        if 'GET' isnt req.method and 'HEAD' isnt req.method
          return next()
        filename = path.join directory or process.cwd(), parseurl(req).pathname
        if path.extname(filename) is '.less'
          console.log "styling ", filename.blue
          cssOptions =
            relativeUrls: true
            filename: filename
            paths: [
              path.dirname(filename)
              directory
              process.cwd()
              ]
          fs.readFileAsync(filename, 'utf-8')
            .then( (rawLess) ->
              less.renderAsync rawLess, cssOptions
            )
            .then( (compiled) ->
              res.type 'text/css'
              res.statusCode = 200
              res.end compiled.css
            )
            .error( (e) ->
              res.statusCode = 500
              res.end e.message
            )
        else
          next()
