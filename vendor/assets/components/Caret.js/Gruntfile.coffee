module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    bower_path: 'bower_components'

    jasmine:
      src: 'src/*.js'
      options:
        vendor: [
          '<%= bower_path %>/jquery/dist/jquery.min.js',
          '<%= bower_path %>/jasmine-jquery/lib/jasmine-jquery.js'
          ]
        specs: 'spec/javascripts/*.js'
        # keepRunner: true

    uglify:
      options:
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      build:
        files:
          'dist/<%= pkg.name %>.min.js': ['src/<%= pkg.name %>.js']

    coffee:
      compileWithMaps:
        options:
          sourceMap: true
        files:
          'src/<%= pkg.name %>.js': 'src/<%= pkg.name %>.coffee'

    'json-replace':
      options:
        space: "  ",
        replace:
          version: "<%= pkg.version %>"
      'update-version':
        files:[{
          'bower.json': 'bower.json',
          'component.json': 'component.json'
        }]

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-json-replace'

  grunt.registerTask 'update-version', 'json-replace'

  grunt.registerTask 'default', ['coffee', 'jasmine','update-version', 'uglify']
  grunt.registerTask 'test', ['coffee', 'jasmine']
