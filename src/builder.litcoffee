Builder is the pipeline of activity to turn a file named on disk to a fully
optimized, built, and inlined output string.

    async = require 'async'
    indent = require 'indent-string'
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
          depth: 0
          start: (op, message) ->
            options.depth += 1
          stop: (op, message) ->
            console.log indent(op, '-', options.depth).blue, message
            options.depth -= 1
          destroy: (el, href) ->
            if href.slice(-12) is 'polymer.html'
              if args['--exclude-polymer']
                console.log "polymer import supressed".yellow
                return true
            return false
          exclude: (el, href) ->
            if href.slice(0, 5) is 'http:'
              return true
            if href.slice(0, 6) is 'https:'
              return true
            if href.slice(0, 5) is 'data:'
              return true
            return false

        waterfall.push (callback) ->
          options.start "building", filename
          importer filename, options, (e, $) ->
            callback e, $
        waterfall.push ($, callback) ->
          scripter $, options, (e, $) ->
            callback e, $
        waterfall.push ($, callback) ->
          styler $, options, (e, $) ->
            callback e, $
        waterfall.push ($, callback) ->
          linker $, options, (e, $) ->
            callback e, $
        async.waterfall waterfall, (e, $) ->
          if e
            console.error("#{e}".red)
          else
            options.stop "building", filename
            callback e, $.html()
