require('coffee-script/register');
module.exports = {
  builder: require('./src/builder.litcoffee'),
  middleware: require('./src/middleware.litcoffee')
}
