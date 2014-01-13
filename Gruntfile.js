module.exports = function(grunt) {

  var jsPath = "app/assets/javascripts/";
  var jsPaths = ['timelines/**/*.js', 'timelines.js', 'timelines_modal.js', 'timelines_select_boxes.js', 'members_form.js', 'members_select_boxes.js'].map(function (e) { return jsPath + e; });

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
      all: {
        files: {
          src: ["app/assets/javascripts/"] //jsPaths
        }
      }
    },
    mocha_phantomjs: {
      all: ['mocha/index.html']
    },
    watch: {
      scripts: {
        files: jsPaths,
        tasks: ['jshint', 'mocha_phantomjs'],
        options: {
          spawn: false,
        },
      },
    },
  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-mocha-phantomjs');

  // Default task(s).
  grunt.registerTask('default', ['jshint']);

};