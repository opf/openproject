module.exports = function() {
  this.plugin('done', function(stats) {

    if (!(process.argv.indexOf('--bail') !== -1 || process.env.CI)) {
      return;
    }

    if (process.env.TRAVIS_IGNORE_TYPESCRIPT) {
      return;
    }

    var errors = stats.compilation.errors;
    if (errors && errors.length) {
      console.error(" ~~ The TYPESCRIPT DISCRUPTOR PLUGIN strikes again. ~~ ");

      for (var i = 0, l = errors.length; i < l; i++) {
        console.error(errors[i]);
      }
      process.exit(2);
    }
  });
};
