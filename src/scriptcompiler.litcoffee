Standard compilation sequence for script source files.

    browserify = require 'browserify'
    path = require 'path'
    fs = require 'fs'

    module.exports = (src, callback) ->
       if path.basename(src) is 'platform.js' or path.basename(src) is 'polymer.js'
         fs.readFile src, 'utf-8', callback
       else
         b = browserify()
         b.add src
         b.transform 'coffeeify'
         b.bundle {}, callback
