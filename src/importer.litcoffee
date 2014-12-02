Recursively work through from a root HTML document, returning a combined
document that has resolved all import statements.

This uses our buddy cheerio, fake server jQuery. Inspired by
vulcanize, though wired up with an asynchronous flow.

    cheerio = require 'cheerio'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    constants = require './constants.litcoffee'
    _ = require 'lodash'
    require 'colors'

This is the key step, look for all import statements and inline
that content recursively. As part of doing this, `src` paths must be
normalized, relative to the import.

    module.exports = processImports = (src, options, callback) ->
      waterfall = []

If the source is provied 'pre read', use this option for the src file name.

      if options['--source']
        pre_read = src
        src = options['--source']
      else
        pre_read = null
      delete options['--source']

      waterfall.push (callback) ->
        options.start "importing", src
        if pre_read
          callback undefined, pre_read
        else
          fs.readFile src, 'utf8', callback

Files without the BOM as a cheerio document.

      waterfall.push (content, callback) ->
        $ = cheerio.load(content.replace(/^\uFEFF/, ''))
        $.filename = src

URL rewriting to absolute paths.

        $(constants.JS_SRC).each ->
          el = $(this)
          js_src = el.attr 'src'
          if js_src and not options?.exclude(el, js_src)
            el.attr 'src', path.resolve(path.join(path.dirname($.filename), js_src))
        $(constants.STYLESHEET).each ->
          el = $(this)
          href = el.attr 'href'
          if href and not options?.exclude(el, href)
            el.attr 'href', path.resolve(path.join(path.dirname($.filename), href))

Nested imports, now things get recursive. Make sure to remove the source flag,
from here on the only thing possible are urls.

        nested_waterfall = []
        $(constants.IMPORTS).each ->
          options = _.extend options
          el = $(this)
          href = el.attr('href')
          if el.attr('skip-vulcanization')? or el.attr('skip-import')?
            #do nothing
          else if options?.destroy el, href
            el.replaceWith "<!-- did not import #{href}-->"
          else
            nested_waterfall.push (callback) ->
              filename = path.resolve(path.dirname($.filename), href)
              if path.basename($.filename) is 'polymer.html'
                if options.importedPolymer
                  console.log 'duplicate polymer supressed'.yellow
                  el.replaceWith "<!-- did not import #{$.filename}-->"
                  callback()
                  return
                else
                  options.importedPolymer = true
              processImports filename, options, (e, $) ->
                if el.attr('nobrowserify')?
                  $('script').each ->
                    $(this).attr('nobrowserify', true)
                el.replaceWith $.html() unless e
                callback(e)
        async.waterfall nested_waterfall, (e) ->
          options.stop "importing", src
          callback e, $

And that is the pipeline, it ends with an error or a fleshed out cheerio
doc.

      async.waterfall waterfall, (e, $) ->
        callback e, $
