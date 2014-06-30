Standard compilation sequence for script source files.

    browserify = require 'browserify'
    path = require 'path'
    fs = require 'fs'
    through = require 'through'
    require 'colors'

    escapeContent = (content) ->
      content.replace(/\\/g, '\\\\').replace(/'/g, '\\\'').replace(/\r?\n/g, '\\n\' +\n    \'')
    contentExport = (content) ->
      "module.exports = '" + escapeContent(content) + "';"
    inliner = (file) ->
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
      if path.extname(file) is '.svg'
        through write, end
      else
        through()



    module.exports = (src, callback) ->
       if path.basename(src) is 'platform.js' or path.basename(src) is 'polymer.js'
         fs.readFile src, 'utf-8', callback
       else
         b = browserify()
         b.add src
         b.transform 'coffeeify'
         b.transform inliner
         b.bundle {}, callback
