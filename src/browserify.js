/*
 * Browserify processing, simple detection based on filename, resulting in
 * fully processed javascript ready to inline.
 */
"use strict";

var path = require('path');
var browserify = require('browserify');

module.exports = function(filename, content, callback) {
  var extensions = ['.js', '.coffee', '.litcoffee'];
  if (extensions.indexOf(path.extname(filename)) > -1) {
    var b = browserify();
    b.add(filename);
    b.transform('coffeeify', {debug: true});
    b.transform('uglifyify', {inline_script: true, beautify: true});
    b.bundle({}, function(e, src){
      if (e) {
        callback(e, filename, content);
      } else {
        callback(undefined, filename, src);
      }
    });
  } else {
    callback(undefined, filename, content);
  }
}
