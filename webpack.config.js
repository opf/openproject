var webpack = require('webpack'),
  path = require('path');

module.exports = {
  context: __dirname + '/app/assets/javascripts/angular',

  entry: './openproject-app.js',

  output: {
    filename: 'openproject-app.bundle.js',
    path: path.join(__dirname, 'app', 'assets', 'javascripts')
  },

  module: {
    loaders: [
      { test: /[\/]angular\.js$/, loader: "exports?angular" }
    ]
  },

  resolve: {
    //root: [path.join(__dirname, 'vendor', 'assets', 'components')]
    modulesDirectories: [
      path.join(__dirname, 'node_modules'),
      path.join(__dirname, 'vendor', 'assets', 'components')
    ]
  },

  externals: { jquery: "jQuery" },

  plugins: [
    new webpack.ProvidePlugin({
      '_':            'lodash',
      'URI':          'URIjs',
      'URITemplate':  'URIjs/src/URITemplate'
    }),
    new webpack.ResolverPlugin([
      new webpack.ResolverPlugin.DirectoryDescriptionFilePlugin(
        'bower.json', ['main'])
    ]) // ["normal", "loader"]
  ]
};
