Recursively work through from a root HTML document, returning a combined
document that has resolved all import statements.

This uses our buddy cheerio, fake server jQuery. Inspired by
vulcanize, though wired up with an asynchronous flow.

    cheerio = require 'cheerio'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    marked = require 'marked'
    constants = require './constants.litcoffee'
    require 'colors'

This is the key step, look for all import statements and inline
that content recursively. As part of doing this, `src` paths must be
normalized, relative to the import.

    module.exports = processImports = (filename, options, callback) ->
      waterfall = []

      waterfall.push (callback) ->
        options.start "importing", filename
        fs.readFile filename, 'utf8', callback

This might be markdown. Give it a shot.

      waterfall.push (content, callback) ->
        if path.extname(filename) is '.md'
          marked content, callback
        else
          callback undefined, content

Files without the BOM as a cheerio document.

      waterfall.push (content, callback) ->
        $ = cheerio.load(content.replace(/^\uFEFF/, ''))
        $.filename = filename

URL rewriting to absolute paths.

        $(constants.JS_SRC).each ->
          el = $(this)
          src = el.attr 'src'
          if src and not options?.exclude(el, src)
            el.attr 'src', path.join(path.dirname($.filename), src)
        $(constants.STYLESHEET).each ->
          el = $(this)
          href = el.attr 'href'
          if href and not options?.exclude(el, href)
            el.attr 'href', path.join(path.dirname($.filename), href)

Nested imports, now things get recursive.

        nested_waterfall = []
        $(constants.IMPORTS).each ->
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
                el.replaceWith $.html() unless e
                callback(e)
        async.waterfall nested_waterfall, (e) ->
          options.stop "importing", filename
          callback e, $

And that is the pipeline, it ends with an error or a fleshed out cheerio
doc.

      async.waterfall waterfall, (e, $) ->
        callback e, $
