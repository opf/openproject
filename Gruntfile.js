module.exports = function(grunt) {

  var jsPath = "app/assets/javascripts/";
  var testSource = "mocha/index.html";
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
      all: {
        files: {
          src: [jsPath]
        }
      }
    },
    mocha_phantomjs: {
      all: [testSource],
      small: {
        src:[testSource],
        options: {
          reporter: "dot"
        }
      },
      cov: {
        src:[testSource],
        options: {
          output: "coverage.json",
          reporter: "json-cov"
        }
      },
      jenkins: {
        src:[testSource],
        options: {
          reporter: "XUnit"
        }
      }
    },
    jscoverage: {
      options: {
        inputDirectory: 'app/assets/javascripts/',
        outputDirectory: 'app/assets/javascripts_cov/'
      }
    },
    watch: {
      scripts: {
        files: [jsPath] ,
        tasks: ['jshint', 'mocha_phantomjs:small'],
        options: {
          spawn: false,
        },
      },
    },
  });

  grunt.loadNpmTasks("grunt-jscoverage");
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-mocha-phantomjs');

  // Default task(s).
  grunt.registerTask('default', ['jshint']);

  var tempPath = "app/assets/javascripts_temp/";
  var covPath = "app/assets/javascripts_cov/";

  grunt.registerTask('moveFiles', 'switch directories for coverage-enabled files and normal files', function () {
    var fs = require("fs");
    fs.renameSync(jsPath, tempPath);
    fs.renameSync(covPath, jsPath);


    fs.renameSync(tempPath + "date-en-US.js", jsPath + "date-en-US.js");
  });

  grunt.registerTask('cleanUpCoverage', 'undo moveFiles', function () {
    var done = this.async();

    var fs = require("fs");
    if (fs.existsSync(tempPath)) {
      fs.renameSync(jsPath, covPath);
      fs.renameSync(tempPath, jsPath);
    }

    if (fs.existsSync("coverage.json")) {
      fs.unlinkSync("coverage.json");
    }

    rmdir = require("rimraf");
    rmdir(covPath, function (e) {
        done(e);
    });
  });

  grunt.registerTask('jsonCov2Html', 'convert coverage to html', function () {
    var exec = require("exec");
    exec("cat coverage.json | node_modules/json2htmlcov/bin/json2htmlcov > coverage.html");
  });

  grunt.registerTask('coverage', ['jscoverage', 'moveFiles', 'mocha_phantomjs:cov', 'jsonCov2Html', 'cleanUpCoverage']);

};