//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

module.exports = function(grunt) {

  var jsPath = "app/assets/javascripts/";

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
    karma: {
      unit: {
        configFile: 'karma.conf.js'
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
        tasks: ['jshint'],
        options: {
          spawn: false,
        },
      },
    },
  });

  grunt.loadNpmTasks("grunt-jscoverage");
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-karma');

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

  grunt.registerTask('coverage', ['jscoverage', 'moveFiles', 'jsonCov2Html', 'cleanUpCoverage']);

};