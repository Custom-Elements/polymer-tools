Link the final output which may combine multiple polymer elements. The idea
here is remove duplicate elements. First one wins.

    constants = require './constants.litcoffee'
    require 'colors'

    module.exports = ($, options, callback) ->
      read = {}
      $('polymer-element').each ->
        polymer = $(this)
        name = polymer.attr('name')
        if read[name]
          console.log "duplicate #{name} stripped".yellow
          polymer.replaceWith ''
        else
           read[name] = true
      callback undefined, $
