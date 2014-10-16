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
        href = el.attr('href').split('?')[0]
        cssOptions =
         filename: href
         paths: [
           path.dirname(href),
           process.cwd()
         ]
        if href and not options?.exclude(el, href)
          waterfall.push (callback) ->
            options.start "styling", href
            per_href = []
            per_href.push (callback) ->
              fs.readFile href, 'utf-8', callback
            per_href.push (content, callback) ->
              content = content.replace(/^\uFEFF/, '')
              parser = new less.Parser cssOptions
              parser.parse content, callback
            per_href.push (content, callback) ->
              try
                callback undefined, content.toCSS cssOptions
              catch e
                callback e
            per_href.push (content, callback) ->
              replacements = []
              (content.match(constants.URL) or []).forEach (dataUrl) ->
                url = dataUrl.replace(/["']/g, "").slice(4, -1)
                url = path.join path.dirname(href), url
                if not options?.exclude(el, url)
                  replacements.push (callback) ->
                    fs.readFile url, 'base64', callback
                  replacements.push (font, callback) ->
                    content = content.replace dataUrl, "url(data:#{mime.lookup(url)};charset=utf-8;base64,#{font})"
                    callback()
              async.waterfall replacements, (e) ->
                callback e, content
            per_href.push (content, callback) ->
              el.replaceWith("<style>#{content}</style>")
              options.stop "styling", href
              callback()
            async.waterfall per_href, callback
      async.waterfall waterfall, (e) ->
        callback e, $
