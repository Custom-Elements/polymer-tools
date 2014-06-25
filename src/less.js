/*
 * Less/CSS transform. This has a simple detection mechanism based on the
 * filename, and will attempt to set a sane set of import directories in order
 * to allow @import... processing.
 */
"use strict";

var path = require('path');
var less = require('less');

module.exports = function(filename, content, callback) {
  var extensions = ['.less'];
  if (extensions.indexOf(path.extname(filename)) > -1) {
    var options = {
      filename: filename,
      paths: [
        path.dirname(filename),
        process.cwd()
      ]
    }
    var parser = new less.Parser(options);
    parser.parse(content, function(e, parsed){
      if (e) {
        callback(e, filename, content);
      } else {
        callback(undefined, filename, parsed.toCSS(options));
      }
    });
  } else {
    callback(undefined, filename, content);
  }
}
