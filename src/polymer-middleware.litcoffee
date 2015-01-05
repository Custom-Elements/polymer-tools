Express middleware to crush out references to polymer.html from polymer
core team elements.

    parseurl = require 'parseurl'
    path = require 'path'
    browserify = require 'browserify'

    module.exports = (args, directory) ->
      (req, res, next) ->
        if 'GET' isnt req.method and 'HEAD' isnt req.method
          return next()
        filename = path.join directory or process.cwd(), parseurl(req).pathname
        if filename.indexOf('bower_components/polymer/polymer.html') > 0
          res.type 'text/html'
          res.statusCode = 200
          res.end ''
        else
          next()
