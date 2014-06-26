Compile stylesheets. These will be totally minimized, since the developer
tools in the browser will always show you what you are looking for.


    less = require 'less'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    constants = require './constants.litcoffee'

    module.exports = ($, options, callback) ->
      waterfall = []
      $(constants.STYLESHEET).each ->
        el = $(this)
        href = el.attr('href')
        if href and not options?.exclude(el, href)
          console.log "  #{href}".blue
          waterfall.push (callback) ->
           fs.readFile href, 'utf-8', callback
          waterfall.push (content, callback) ->
           content = content.replace(/^\uFEFF/, '')
           options =
             filename: href
             paths: [
               path.dirname(href),
               process.cwd()
             ]
           parser = new less.Parser(options);
           parser.parse content, (e, parsed) ->
             if not e and parsed
               el.replaceWith("<style>#{parsed.toCSS(options)}</style>")
             callback e
      async.waterfall waterfall, (e) ->
        callback e, $
