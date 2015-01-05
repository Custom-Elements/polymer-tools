Command line wrapper for polymer element compiling server. This uses
a set of custom middleware to give you Polymer elements on the fly
with LESS/CoffeeScript/Browserify support built in.

The idea is that `<link rel="import">` tags will request content from this
server, which will be transpiled into polymer ready browser custom elements.

    doc = """
    Usage:
      polymer-serve [options] <root_directory>


      --help             Show the help
      --cache            Only build just once, then save the results.
      --quiet            SSSHHH! Less logging.
    """
    {docopt} = require 'docopt'
    _ = require 'lodash'
    args = docopt(doc)
    path = require 'path'
    fs = require 'fs'
    express = require 'express'
    livereload = require 'livereload'
    wrench = require 'wrench'
    require 'colors'

    args.root_directory = fs.realpathSync args['<root_directory>'] or '.'

    port = process.env['PORT'] or 10000
    console.log "Polymer Build Server".blue, args.root_directory
    app = express()
    app.use require('./polymer-middleware.litcoffee')(args, args.root_directory)
    app.use require('./style-middleware.litcoffee')(args, args.root_directory)
    app.use require('./script-middleware.litcoffee')(args, args.root_directory)
    app.use express.static(args.root_directory)
    app.listen port
    console.log "Live Reload".blue, args.root_directory
    reload = livereload.createServer()
    reload.watch args.root_directory
    if fs.existsSync path.join(args.root_directory, 'demo.html')
      console.log "Test Page".blue, "http://localhost:#{port}/demo.html"
