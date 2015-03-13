//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

var fs = require('fs');
var globSync = require('glob').sync;
var bodyParser = require('body-parser');
var mocks = globSync('./tests/integration/mocks/**/*.js', {
  cwd: __dirname
}).map(require);

var express = require('express');
var railsRoot = __dirname + '/..';
var appRoot   = __dirname;
var app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({
  extended: true
}));

mocks.forEach(function(route) {
  route(app);
});

app.use(express.static(appRoot + '/public'));
app.use('/assets', express.static(railsRoot + '/app/assets/javascripts'));
app.use('/assets', express.static(railsRoot + '/app/assets/images'));
app.use('/javascripts', express.static(railsRoot + '/public/javascripts'));

app.use('/bower_components', express.static(appRoot + '/bower_components'));

app.get('/work_packages*', function(req, res) {
  fs.readFile(appRoot + '/public/index.html', 'utf8', function(err, text) {
    res.send(text);
  });
});

module.exports = app;
