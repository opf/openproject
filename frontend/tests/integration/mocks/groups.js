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
  var express = require('express');

  var availableColumnsRouter = express.Router();
  availableColumnsRouter.get('/', function(req, res) {
    res.send({
      "available_columns": []
    });
  });

  var customFieldFiltersRouter = express.Router();
  customFieldFiltersRouter.get('/', function(req, res) {
    res.send({
      "custom_field_filters": []
    });
  });

  var groupedRouter = express.Router();
  groupedRouter.get('/', function(req, res) {
    res.send({
      "user_queries": [],
      "queries": []
    });
  });

  app.use('/api/experimental/queries/available_columns',
    availableColumnsRouter);
  app.use('/api/experimental/queries/custom_field_filters',
    customFieldFiltersRouter);
  app.use('/api/experimental/projects/:id/queries/custom_field_filters',
    customFieldFiltersRouter);
  app.use('/api/experimental/queries/grouped', groupedRouter);
};
