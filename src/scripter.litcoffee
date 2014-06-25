Useful after all the imports are done, whip through all the
script tags in the combined imported document and browserify them.

    path = require 'path'
    fs = require 'fs'
    browserify = require 'browserify'
    async = require 'async'
    constants = require './constants.litcoffee'

    readFile = (filename) ->
      content = fs.readFileSync(filename, 'utf8')

    module.exports = ($, options, callback) ->
     waterfall = []
     $(constants.JS_SRC).each ->
       el = $(this)
       src = el.attr('src')
       if src
         waterfall.push (callback) ->
           b = browserify()
           b.add src
           b.transform 'coffeeify'
           b.transform 'uglifyify',
             inline_script: true
             beautify: true
           b.bundle {}, (e, content) ->
             content = content.replace(/<\x2fscript([>\/\t\n\f\r ])/gi, "<\\/script$1")
             el.replaceWith('<script>' + content + '</script>')
             callback e
      async.waterfall waterfall, (e) ->
        callback e, $
