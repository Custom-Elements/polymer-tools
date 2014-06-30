Recursively work through from a root HTML document, returning a combined
document that has resolved all import statements.

This uses our buddy cheerio, fake server jQuery. Inspired by
vulcanize, though wired up with an asynchronous flow.

    cheerio = require 'cheerio'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    constants = require './constants.litcoffee'

Files without the BOM as a document.

    readFile = (filename) ->
      content = fs.readFileSync(filename, 'utf8')
      $ = cheerio.load(content.replace(/^\uFEFF/, ''))
      $.filename = filename
      $

This is the key step, look for all import statements and inline
that content recursively. As part of doing this, `src` paths must be
normalized, relative to the import.

    processImports = ($, options, callback) ->
      waterfall = []
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
      $(constants.IMPORTS).each ->
        el = $(this)
        href = el.attr('href')
        if el.attr('skip-vulcanization')? or el.attr('skip-import')?
          #do nothing
        else if options?.destroy el, href
          el.replaceWith ''
        else
          waterfall.push (callback) ->
            filename = path.resolve(path.dirname($.filename), href)
            processImports readFile(filename), options, (e, $) ->
              el.replaceWith $.html()
              callback(e)
      async.waterfall waterfall, (e) ->
        callback e, $

This is it, the importer.
### filename
Just a string, points to the file to read and resolve imports
### options
Looks for an `exclude(el, href)`, passed a cheerio element and the href
to be imports. This gives you the ability to exclude any file, which
most specifically is useful to exclude polymer itself when building polymer
core team's elements.
### callback(err, $)
Callback with a cheerio document.

    module.exports = (filename, options, callback) ->
      processImports readFile(filename), options, callback
