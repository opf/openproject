
module.exports = (grunt) ->
  
  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    meta:
      banner:
        "/*! <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today(\"yyyy-mm-dd\") %>\n" +
        "* Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.name %> <<%=pkg.author.email%>>; \n" +
        "* homepage: <%= pkg.homepage %> \n" +
        "* Licensed <%= pkg.license %>\n" +
        "*/\n\n"

    coffee:
      dist:
        options:
          bare: true, join: true
        files:
          'src/build/<%= pkg.name %>.js': [
            'src/app.coffee',
            'src/controller.coffee',
            'src/model.coffee',
            'src/view.coffee',
            'src/default.coffee',
            'src/api.coffee'
          ]
      specs:
        files:[
          {
            expand: true, cwd: 'spec/javascripts', ext: ".spec.js",
            src: '*.spec.coffee', dest: 'spec/build/javascripts',
          },
          src: 'spec/spec_helper.coffee', dest: 'spec/build/spec_helper.js'
        ]

    copy:
      css: {src: 'src/jquery.atwho.css', dest: 'dist/css/jquery.atwho.css'}

    concat:
      options:
        banner: "<%= meta.banner %>"
      dist:
        src: ['src/wrapper_header.js', 'src/build/<%= pkg.name %>.js', 'src/wrapper_footer.js'],
        dest: 'dist/js/<%= pkg.name %>.js'

    uglify:
      dist:
        src: 'dist/js/<%= pkg.name %>.js', dest: 'dist/js/<%= pkg.name %>.min.js'
    cssmin:
      minify: {src: 'src/jquery.atwho.css', dest: 'dist/css/jquery.atwho.min.css'}

    watch:
      coffee:
        files: ['src/*.coffee', 'spec/javascripts/*.spec.coffee', 'spec/spec_helper.coffee']
        tasks: ['compile', 'notify']
      test:
        options:
          debounceDelay: 250
        files: ['spec/javascripts/*.spec.coffee', 'spec/spec_helper.coffee']
        tasks: ['test', 'notify']

    jasmine:
      dist:
        src: 'dist/js/<%= pkg.name %>.js',
        options:
          keepRunner: true
          styles: 'dist/css/<%= pkg.name %>.css',
          specs: 'spec/build/javascripts/*.spec.js',
          vendor: [
            'bower_components/jQuery/dist/jquery.js',
            'bower_components/Caret.js/src/*.js'
          ],
          helpers: [
            'bower_components/jasmine-jquery/lib/jasmine-jquery.js',
            'spec/build/spec_helper.js',
            'spec/helpers/*.js'
          ]

    connect:
      tests:
        options:
          keepalive: true,
          open:
            target: 'http://localhost:8000/_SpecRunner.html'

    'json-replace':
      options:
        space: "  ",
        replace:
          version: "<%= pkg.version %>"
      'update-version':
        files:[
          {src: 'bower.json', dest: 'bower.json'},
          {src: 'component.json', dest: 'component.json'}
        ]

    notify:
      success:
        options:
          message: 'Build Successfully'


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-json-replace'
  grunt.loadNpmTasks 'grunt-notify'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'

  # alias
  grunt.registerTask 'update-version', 'json-replace'
  grunt.registerTask 'compile', ['coffee', 'concat', 'copy', 'cssmin']

  grunt.registerTask "server", ["compile", "jasmine:dist:build", "connect"]
  grunt.registerTask "test", ["compile", "jasmine"]
  grunt.registerTask "default", ['test', 'uglify', 'update-version']
