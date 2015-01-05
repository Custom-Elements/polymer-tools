Express middleware to build and serve on demand.

    parseurl = require 'parseurl'
    path = require 'path'
    browserify = require 'browserify'

    module.exports = (args, directory) ->
      (req, res, next) ->
        if 'GET' isnt req.method and 'HEAD' isnt req.method
          return next()
        filename = path.join directory or process.cwd(), parseurl(req).pathname
        if path.extname(filename) is '.litcoffee' or path.extname(filename) is '.coffee'
          console.log "scripting with browserify", filename.blue
          b = browserify()
          b.add filename
          b.transform require('coffeeify')
          b.bundle (err, compiled) ->
            if err
              res.statusCode = 500
              res.end "#{err}"
            else
              res.type 'application/javascript'
              res.statusCode = 200
              res.end compiled
        else
          next()
