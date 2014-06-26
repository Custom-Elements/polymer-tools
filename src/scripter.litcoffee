Useful after all the imports are done, whip through all the
script tags in the combined imported document and browserify them.

    path = require 'path'
    fs = require 'fs'
    browserify = require 'browserify'
    async = require 'async'
    constants = require './constants.litcoffee'
    uglify = require 'uglify-js'

    readFile = (filename) ->
      content = fs.readFileSync(filename, 'utf8')

    module.exports = ($, options, callback) ->
     waterfall = []
     $(constants.JS_SRC).each ->
       el = $(this)
       src = el.attr('src')

Important to not browserify platform or polymer itself.

       if src and not options?.exclude(el, src)
         waterfall.push (callback) ->
           if path.basename(src) is 'platform.js' or path.basename(src) is 'polymer.js'
             fs.readFile src, 'utf-8', callback
           else
             b = browserify()
             b.add src
             b.transform 'coffeeify'
             b.bundle {}, callback
         waterfall.push (content, callback) ->
             content = content.replace(/<\x2fscript([>\/\t\n\f\r ])/gi, "<\\/script$1")
             ast = uglify.parse(content)
             content = ast.print_to_string
               inline_script: true
               beautify: true
             el.replaceWith "<script built='#{src}'>#{content}</script>"
             callback()
      async.waterfall waterfall, (e) ->
        callback e, $
