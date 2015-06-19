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

module.exports = function(app) {
  var fs = require('fs');
  var express = require('express');
  var workPackagesRouter = express.Router();
  workPackagesRouter.get('/', function(req, res) {
    res.send({'work_packages':[]});
  });
  workPackagesRouter.get('/:id', function(req, res) {
    fs.readFile(__dirname + '/work-packages/' + req.params.id + '.json', 'utf8', function(err, text) {
      res.send(text);
    });
  });
  workPackagesRouter.post('/:id/form', function(req, res) {
    fs.readFile(
      __dirname + '/work-packages/' + req.params.id + '_form.json',
      'utf8',
      function(err, text) {
        res.send(text);
    });
  });
  workPackagesRouter.patch('/821', function(req, res) {
    fs.readFile(__dirname + '/work-packages/821_patch.json', 'utf8', function(err, text) {
      res.status(409);
      res.send(text);
    });
  });
  workPackagesRouter.patch('/:id', function(req, res) {
    fs.readFile(
      __dirname + '/work-packages/' +
        req.params.id +
      '_patch.json', 'utf8', function(err, text) {
      res.send(text);
    });
  });
  workPackagesRouter.get('/schemas/:name', function(req, res) {
    fs.readFile(
      __dirname + '/work-packages/schemas/' +
        req.params.name +
      '.json', 'utf8', function(err, text) {
      res.send(text);
    });
  });

  app.use('/api/v3/work_packages', workPackagesRouter);

  var textileRouter = express.Router();
  textileRouter.post('/', function(req, res) {
    var workPackageId = req.url.split('/').pop();
    fs.readFile(
      __dirname +
        '/work-packages/' +
        workPackageId +
      '_textile.html', 'utf8', function(err, text) {
      res.send(text);
    });
  });

  app.use('/api/v3/render/textile', textileRouter);

  app.get('/work_packages/auto_complete.json*', function(req, res) {
    res.send('[]');
  });
};
