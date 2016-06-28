module.exports = function() {
  this.plugin('done', function(stats) {

    if (!(process.argv.indexOf('--bail') !== -1 || process.env.CI)) {
      return;
    }

    if (stats.compilation.errors && stats.compilation.errors.length) {
      console.error(" ~~ The TYPESCRIPT DISCRUPTOR PLUGIN strikes again. ~~ ");
      process.exit(2);
    }
  });
};
