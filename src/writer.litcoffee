Write out a target file, making sure the directories exist.

    mkdirp = require 'mkdirp'
    fs = require 'fs'
    path = require 'path'
    require 'colors'

    module.exports = (args, file) ->
      targetfile = path.join args.build_directory, file.replace(args.source_directory, '')
      (content, callback) ->
        console.log "writing #{targetfile}".green
        mkdirp path.dirname(targetfile), (e) ->
          if e
            callback(e)
          else
            fs.writeFile targetfile, content, callback
