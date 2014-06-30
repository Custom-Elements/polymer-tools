Command line wrapper runner for vulcanization.

    doc = """
    Usage:
      polymer-build [options] watch <root_directory> <source_directory> <build_directory> [<only_these>...]
      polymer-build [options] <source_directory> <build_directory> [<only_these>...]


      --help             Show the help
      --exclude-polymer  When building kits with polymer elements from the core
                         team, skip importing polymer itself to avoid dual init
      --copy-polymer     When going to the <build_directory> copy over polymer
                         itself to the destination. Useful for whole apps.
    """
    {docopt} = require 'docopt'
    _ = require 'lodash'
    args = docopt(doc)
    path = require 'path'
    fs = require 'fs'
    mkdirp = require 'mkdirp'
    chokidar = require 'chokidar'
    express = require 'express'
    livereload = require 'express-livereload'
    wrench = require 'wrench'
    async = require 'async'
    builder = require './builder.litcoffee'
    scriptcompiler = require './scriptcompiler.litcoffee'
    configcompiler = require './configcompiler.litcoffee'
    writer = require './writer.litcoffee'
    middleware = require './middleware.litcoffee'
    require 'colors'

    mkdirp args['<build_directory>'], ->
      args.source_directory = fs.realpathSync args['<source_directory>']
      args.build_directory = fs.realpathSync args['<build_directory>']
      args.root_directory = fs.realpathSync args['<root_directory>'] or '.'

      #anything that looks like a config file
      wrench.copyDirSyncRecursive args.source_directory, args.build_directory, {
        forceDelete: true
        include: '\.(json|yaml)$'
      }

This waterfall is the build pipeline.

      waterfall = []

Optional file limiting.

      processFile = (filename) ->
        (args['<only_these>'].length is 0 or path.basename(filename) in args['<only_these>'])

Need polymer?

        if args['--copy-polymer']
          waterfall.push (callback) ->
            wrench.copyDirRecursive path.join(__dirname, '..', 'node_modules', 'polymer'),
              path.join(args.build_directory, 'polymer'), forceDelete: true, callback

Asset directories, this is just a copy. Tack on more directories if you need.

      for dir in ['images', 'media']
        do ->
          assets = dir
          waterfall.push (callback) ->
            src = path.join args.source_directory, assets
            build = path.join args.build_directory, assets
            fs.exists src, (exists) ->
              if exists
                wrench.copyDirRecursive src, build, forceDelete: true, callback
              else
                callback()

Whip through all the source files and build them as needed.

      _(wrench.readdirSyncRecursive args.source_directory)
        .select processFile
        .map (file) -> path.join(args.source_directory, file)
        .each (file) ->
          if path.extname(file) is '.html'
            waterfall.push (callback) ->
              builder(args) file, callback
            waterfall.push writer(args, file)
          if path.extname(file) is '.js'
            targetfile = path.join args.build_directory, file.replace(args.source_directory, '')
            waterfall.push (callback) ->
              scriptcompiler file, callback
            waterfall.push writer(args, file)
          if path.extname(file) is '.yaml'
            targetfile = path.join args.build_directory, file.replace(args.source_directory, '')
            waterfall.push writer(args, file)
          if path.extname(file) is '.json'
            targetfile = path.join args.build_directory, file.replace(args.source_directory, '')
            waterfall.push (callback) ->
              configcompiler(args) file, callback
            waterfall.push writer(args, file)

At this point the waterfall is built and ready to run.

      async.waterfall waterfall, (e) ->
        console.error("#{e}".red) if e

Are we watching?

        if args.watch
          port = process.env['PORT'] or 10000
          app = express()
          app.use express.static(args.root_directory)
          livereload app,
            port: 35729
            watchDir: args.build_directory
          app.listen port
          console.log "http://localhost:#{port}/demo.html"
          watcher = chokidar.watch args.source_directory
          watcher.on 'change', ->
            async.waterfall waterfall, (e) ->
              console.error("#{e}".red) if e
          server = require('custom-event-server') debug: true
          server.on 'beep', (name, detail, client) ->
            client.fire 'boop', {}
          server.on 'woot', (name, detail, client) ->
            console.log 'ahhh!'
          server.listen port + 1
          console.log "ws://localhost:#{port+1} server events"
