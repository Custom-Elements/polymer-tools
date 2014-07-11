Useful after all the imports are done, whip through all the
script tags in the combined imported document and browserify them.

    path = require 'path'
    fs = require 'fs'
    scriptcompiler = require './scriptcompiler.litcoffee'
    async = require 'async'
    constants = require './constants.litcoffee'
    uglify = require 'uglify-js'

    module.exports = ($, options, callback) ->
     waterfall = []
     $(constants.JS_SRC).each ->
       el = $(this)
       src = el.attr('src')


       if src and not options?.exclude(el, src)
         waterfall.push (callback) ->
           options.start "scripting", src
           scriptcompiler options, src, callback
         waterfall.push (content, callback) ->
           options.stop "scripting", src
           content = content.replace(/<\x2fscript([>\/\t\n\f\r ])/gi, "<\\/script$1")
           ast = uglify.parse(content)
           content = ast.print_to_string
             inline_script: true
             beautify: true
           el.replaceWith "<script built='#{src}'>#{content}</script>"
           callback()
      async.waterfall waterfall, (e) ->
        callback e, $
