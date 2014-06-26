Builder is the pipeline of activity to turn a file named on disk to a fully
optimized, built, and inlined output string.

    async = require 'async'
    importer = require './importer.litcoffee'
    scripter = require './scripter.litcoffee'
    styler = require './styler.litcoffee'
    linker = require './linker.litcoffee'

    module.exports = (args) ->
      (filename, callback) ->
        waterfall = []

Here is a bit of a special case, prevent polymer from being imported, this
will allow us to use polymer core elements without conflicts arising from
having two different references to polymer.

        options =
          destroy: (el, href) ->
            if args['--exclude-polymer']
              if href.slice(-12) is 'polymer.html'
                return true
            return false
          exclude: (el, href) ->
            if href.slice(0, 4) is 'http'
              return true
            return false

        waterfall.push (callback) ->
          console.log "importing #{filename}".blue
          importer filename, options, (e, $) ->
            callback e, $
        waterfall.push ($, callback) ->
          console.log "compiling script #{filename}".blue
          scripter $, options, (e, $) ->
            callback e, $
        waterfall.push ($, callback) ->
          console.log "compiling styles #{filename}".blue
          styler $, options, (e, $) ->
            callback e, $
        waterfall.push ($, callback) ->
          console.log "linking #{filename}".blue
          linker $, options, (e, $) ->
            callback e, $.html()
        async.waterfall waterfall, (e, content) ->
          console.error("#{e}".red) if e
          callback e, content
