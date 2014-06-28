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

      #classic asset directories
      for assets in ['images', 'media']
        if fs.existsSync path.join(args.source_directory, assets)
          wrench.copyDirSyncRecursive path.join(args.source_directory, assets),
            path.join(args.build_directory, assets), forceDelete: true


      processFile = (filename) ->
        path.extname(filename) is '.html' and
          (args['<only_these>'].length is 0 or
          path.basename(filename) in args['<only_these>'])

      waterfall = []

      _(wrench.readdirSyncRecursive args.source_directory)
        .select processFile
        .map (file) -> path.join(args.source_directory, file)
        .each (file) ->
          console.log "found #{file}".blue
          targetfile = path.join args.build_directory, file.replace(args.source_directory, '')
          waterfall.push (callback) ->
            builder(args) file, callback
          waterfall.push (content, callback) ->
            console.log "writing #{targetfile}".blue
            mkdirp path.dirname(targetfile), (e) ->
              if e
                callback(e)
              else
                fs.writeFile targetfile, content, callback
          waterfall.push (callback) ->
            console.log "complete #{targetfile}".green
            callback()

Need polymer?

        if args['--copy-polymer']
          waterfall.push (callback) ->
            wrench.copyDirRecursive path.join(__dirname, '..', 'node_modules', 'polymer'),
              path.join(args.build_directory, 'polymer'), forceDelete: true, callback

At this point the waterfall is built and ready to run.

      async.waterfall waterfall, (e) ->
        console.error("#{e}".red) if e


Are we watching?

        if args.watch
          port = process.env['PORT'] or 10000
          app = express()
          app.use middleware(process.cwd())
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
