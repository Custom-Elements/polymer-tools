Standard compilation sequence for script source files.

    browserify = require 'browserify'
    path = require 'path'
    fs = require 'fs'
    through = require 'through'
    require 'colors'

Given an extension of a file, create a browserify transform to just turn it
into a string constant in source.

    requireString = (extension) ->
      escapeContent = (content) ->
        content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'')
      contentExport = (content) ->
        "module.exports = '" + escapeContent(content) + "';"
      (file) ->
        data = ''
        write = (buffer) ->
          data += buffer
        end = ->
          try
            content = fs.readFileSync file, 'utf8'
          catch e
            this.emit 'error', e
          this.queue contentExport(content)
          this.queue null
        if path.extname(file) is extension
          through write, end
        else
          through()

Important to not browserify platform or polymer itself.
**NOTE**: Can use `nobrowserify` to exclude certain scripts if you want to import them the old fashioned way.

    module.exports = (options, el, src, callback) ->
       if path.basename(src) is 'platform.js' or path.basename(src) is 'polymer.js' or el.attr?('nobrowserify')?
         if path.basename(src) is 'polymer.js'
           if options.importedPolymerJS
             console.log "duplicate polymer.js supressed".yellow
             callback undefined, ''
             return
            else
              options.importedPolymerJS = true
         console.log "inline sourcing #{src}".yellow
         fs.readFile src, 'utf-8', callback
       else
         b = browserify()
         b.add src
         b.transform require('coffeeify')
         b.transform requireString '.svg'
         b.bundle callback
