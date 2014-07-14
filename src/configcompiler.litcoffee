Deal with json files, which may be configuration, specifically
looking for `manifest.json` files  which could use some special
handling when we are making chrome extensions.

    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    _ = require 'lodash'
    scriptcompiler = require './scriptcompiler.litcoffee'
    writer = require './writer.litcoffee'
    require 'colors'

    module.exports = (args) ->
      (src, callback) ->
        waterfall = []
        waterfall.push (callback) ->
          fs.readFile src, 'utf8', callback
        waterfall.push (content, callback) ->
          config = JSON.parse(content)
          if config?.version
            console.log "looks like a chrome extension".blue
          if config?.content_scripts
            console.log "looks like a chrome content script".blue
            scriptswaterfall = []
            config.content_scripts = _.map config.content_scripts, (s) ->
              s.js = _.map s.js, (scriptname) ->
                ext = path.extname(scriptname)
                scriptnamejs = scriptname.replace new RegExp("#{ext}$"), ".js"

Compile the referenced script by extending the waterfall.

                scriptsrc = path.join path.dirname(src), scriptname
                scriptbuild = path.join path.dirname(src), scriptnamejs
                scriptswaterfall.push (callback) ->
                  callback undefined, args, scriptsrc
                scriptswaterfall.push scriptcompiler
                scriptswaterfall.push writer(args, scriptbuild)

End of the map back into the config object.

                scriptnamejs

End of the map of `content_scripts`.

              s

          async.waterfall scriptswaterfall, (e) ->
            content = JSON.stringify config
            callback undefined, content

Fire up the config compilation waterfall.

        async.waterfall waterfall, callback
