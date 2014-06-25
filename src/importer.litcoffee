Recursively work through from a root HTML document, returning a combined
document that has resolved all import statements.

This uses our buddy cheerio, fake server jQuery. Inspired by
vulcanize, though wired up with an asynchronous flow.

    cheerio = require 'cheerio'
    path = require 'path'
    fs = require 'fs'
    async = require 'async'
    constants = require './constants.js'

Files without the BOM.

    readFile = (filename) ->
      content = fs.readFileSync(filename, 'utf8')
      $ = cheerio.load(content.replace(/^\uFEFF/, ''))
      $.filename = filename
      $

This is the key step, look for all import statements and inline
that content recursively.

    processImports = ($, options, callback) ->
      waterfall = []
      $(constants.IMPORTS).each ->
        el = $(this)
        href = el.attr('href')
        if el.attr('skip-vulcanization')? or el.attr('skip-import')?
          #do nothing
        else if options?.exclude el, href
          el.replaceWith ''
        else
          waterfall.push (callback) ->
            filename = path.resolve(path.dirname($.filename), href)
            processImports readFile(filename), options, (e, content) ->
              el.replaceWith(content)
              callback(e)
      async.waterfall waterfall, ->
        callback undefined, $.html()

This is it, the importer.

    module.exports = (filename, options, callback) ->
      processImports readFile(filename), options, callback
