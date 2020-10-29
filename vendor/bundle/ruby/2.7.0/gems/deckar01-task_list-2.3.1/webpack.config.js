module.exports = {
  entry: './app/assets/javascripts/task_list.coffee',
  output: {
    filename: 'task_list.js',
    libraryTarget: 'umd',
    library: 'TaskList',
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        loader: 'coffee-loader'
      }
    ]
  },
  resolve: {
    extensions: ['.coffee', '.js']
  }
}
