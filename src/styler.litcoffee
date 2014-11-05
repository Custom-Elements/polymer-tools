Compile stylesheets. These will be totally minimized, since the developer
tools in the browser will always show you what you are looking for.


    less = require 'less'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    mime = require 'mime'
    constants = require './constants.litcoffee'

'?' Is an illegal filesystem charachter so we're going to take the
stuff before it. '#' is not supported either!

    urlPathScrub = (url) ->
      url.split('?')?[0]?.split('#')?[0]

    module.exports = ($, options, callback) ->
      waterfall = []
      $(constants.STYLESHEET).each ->
        el = $(this)
        console.log el.attr('href')
        href = urlPathScrub el.attr('href')
        cssOptions =
          relativeUrls: true
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
              less.render content, cssOptions, callback
            per_href.push (content, callback) ->
              replacements = []
              css = content.css
              (css.match(constants.URL) or []).forEach (dataUrl) ->
                url = dataUrl.replace(/["']/g, "").slice(4, -1)
                url = urlPathScrub url
                url = path.join path.dirname(href), url
                if not options?.exclude(el, url) and not url.slice(0, 4) is 'data'
                  replacements.push (callback) ->
                    fs.readFile url, 'base64', callback
                  replacements.push (font, callback) ->
                    css = css.replace dataUrl, "url(data:#{mime.lookup(url)};charset=utf-8;base64,#{font})"
                    callback()
              async.waterfall replacements, (e) ->
                callback e, css
            per_href.push (css, callback) ->
              el.replaceWith("<style>#{css}</style>")
              options.stop "styling", href
              callback()
            async.waterfall per_href, callback
      async.waterfall waterfall, (e) ->
        callback e, $
