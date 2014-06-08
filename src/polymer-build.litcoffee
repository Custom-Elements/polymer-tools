Command line wrapper runner for vulcanization.

    doc = """
    Usage:
      polymer-build <source_directory> <build_directory>
    """
    {docopt} = require 'docopt'
    args = docopt(doc)
    vulcanize = require 'vulcanize'
    recursive = require 'recursive-readdir'
    path = require 'path'
    fs = require 'fs'
    mkdirp = require 'mkdirp'
    async = require 'async'
    require 'colors'

    args.source_directory = fs.realpathSync args['<source_directory>']
    args.build_directory = fs.realpathSync args['<build_directory>']


    waterfall = []

    waterfall.push (callback) ->
      mkdirp args.build_directory, callback

    recursive args.source_directory, (err, files) ->
      files.forEach (file) ->
        if path.extname(file) is '.html'
          console.log "found #{file}".blue
          waterfall.push (callback) ->
            vulcanizeOptions =
              preprocess: ['vulcanize-less', 'vulcanize-browserify']
              inline: true
              input: file
              output: file.replace(args.source_directory, args.build_directory)
              outputDir: path.dirname(file.replace(args.source_directory, args.build_directory))
            vulcanize.setOptions vulcanizeOptions, (e) ->
              console.log "building #{vulcanizeOptions}".green
              if e
                callback(e)
              else
                vulcanize.processDocument callback

      async.waterfall waterfall, (e) ->
        if e
          console.error "#{e}".red

