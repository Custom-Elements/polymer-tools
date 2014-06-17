Command line wrapper runner for vulcanization.

    doc = """
    Usage:
      polymer-build [options] watch <root_directory> <source_directory> <build_directory> [<only_these>...]
      polymer-build [options] <source_directory> <build_directory> [<only_these>...]


      --help             Show the help
      --exclude-polymer  When building kits with polymer elements from the core
                         team, skip importing polymer itself to avoid dual init
    """
    {docopt} = require 'docopt'
    args = docopt(doc)
    vulcanize = require 'vulcanize'
    recursive = require 'recursive-readdir'
    path = require 'path'
    fs = require 'fs'
    mkdirp = require 'mkdirp'
    async = require 'async'
    chokidar = require 'chokidar'
    express = require 'express'
    livereload = require 'express-livereload'
    wrench = require 'wrench'
    require 'colors'


    mkdirp args['<build_directory>'], ->
      args.source_directory = fs.realpathSync args['<source_directory>']
      args.build_directory = fs.realpathSync args['<build_directory>']
      args.root_directory = fs.realpathSync args['<root_directory>'] or '.'

      for assets in ['images', 'media']
        if fs.existsSync path.join(args.source_directory, assets)
          wrench.copyDirSyncRecursive path.join(args.source_directory, assets),
            path.join(args.build_directory, assets), forceDelete: true


      processFile = (filename) ->
        path.extname(filename) is '.html' and
          (args['<only_these>'].length is 0 or
          path.basename(filename) in args['<only_these>'])

      waterfall = []

      recursive args.source_directory, (err, files) ->
        files.forEach (file) ->
          if processFile(file)
            console.log "found #{file}".blue
            waterfall.push (callback) ->
              vulcanizeOptions =
                preprocess: ['vulcanize-less', 'vulcanize-browserify']
                inline: true
                strip: true
                input: file
                output: file.replace(args.source_directory, args.build_directory)
                outputDir: path.dirname(file.replace(args.source_directory, args.build_directory))

Here is a bit of a special case, prevent polymer from being imported, this
will allow us to use polymer core elements without conflicts arising from
havign two different references to polymer.

              if args['--exclude-polymer']
                vulcanizeOptions.excludes =
                  imports: ['polymer.html']
              vulcanize.setOptions vulcanizeOptions, (e) ->
                console.log "building #{vulcanizeOptions.input} to #{vulcanizeOptions.output}".blue
                if e
                  callback(e)
                else
                  vulcanize.processDocument (e) ->
                    console.log "built #{vulcanizeOptions.input}".green
                    callback(e)

At this point the waterfall is built and ready to run.

        async.waterfall waterfall, (e) ->
          console.error("#{e}".red) if e

Are we watching?

        if args.watch
          port = process.env['PORT'] or 10000
          app = express()
          app.use(express.static(args.root_directory))
          livereload app,
            port: 35729
            watchDir: args.build_directory
          app.listen port
          console.log "http://localhost:#{port}/demo.html"
          watcher = chokidar.watch args.source_directory
          watcher.on 'change', ->
            async.waterfall waterfall, (e) ->
              console.error("#{e}".red) if e



