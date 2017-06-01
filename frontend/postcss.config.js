var fs = require('fs');
var path = require('path');
var _ = require('lodash');
var autoprefixer = require('autoprefixer');

var browsersListConfig = fs.readFileSync(path.join(__dirname, '..', 'browserslist'), 'utf8');
var browsersList = _.filter(browsersListConfig.split('\n'), function (entry) {
  return entry && entry.charAt(0) !== '#';
});

module.exports = {
  plugins: [
    autoprefixer({
      browsers: browsersList, cascade: false
    })
  ]
}
