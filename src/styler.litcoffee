Compile stylesheets. These will be totally minimized, since the developer
tools in the browser will always show you what you are looking for.


    less = require 'less'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    mime = require 'mime'
    constants = require './constants.litcoffee'

    module.exports = ($, options, callback) ->
      waterfall = []
      $(constants.STYLESHEET).each ->
        el = $(this)
        href = el.attr('href')
        cssOptions =
         filename: href
         paths: [
           path.dirname(href),
           process.cwd()
         ]
        if href and not options?.exclude(el, href)
          waterfall.push (callback) ->
            options.start "styling", href
            fs.readFile href, 'utf-8', callback
          waterfall.push (content, callback) ->
            content = content.replace(/^\uFEFF/, '')
            parser = new less.Parser cssOptions
            parser.parse content, callback
          waterfall.push (content, callback) ->
            callback undefined, content.toCSS cssOptions
          waterfall.push (content, callback) ->
            content = content.replace constants.URL, (match) ->
              url = match.replace(/["']/g, "").slice(4, -1)
              if not options?.exclude(el, url)
                url = path.join path.dirname(href), url
                data = fs.readFileSync(url).toString('base64')
                return "url(data:#{mime.lookup(url)};charset=utf-8;base64,#{data})"
            callback undefined, content
          waterfall.push (content, callback) ->
            el.replaceWith("<style>#{content}</style>")
            options.stop "styling", href
            callback()
      async.waterfall waterfall, (e) ->
        callback e, $
