//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

angular.module('openproject.timelines.models')
  .factory('Color', require('./color'))
  .factory('CustomField', require('./custom-field'))
  .factory('HistoricalPlanningElement', require('./historical-planning-element'))
  .factory('Constants', require('./mixins/constants'))
  .factory('UI', ['$timeout', require('./mixins/ui')])
  .factory('PlanningElementType', require('./planning-element-type'))
  .factory('PlanningElement', ['PathHelper', require('./planning-element')])
  .factory('ProjectAssociation', require('./project-association'))
  .factory('ProjectType', require('./project-type'))
  .factory('Project', ['PathHelper', require('./project')])
  .factory('Reporting', require('./reporting'))
  .factory('Status', require('./status'))
  .factory('Timeline', ['Constants', 'TreeNode', 'UI', 'Color',
    'HistoricalPlanningElement', 'PlanningElement', 'PlanningElementType',
    'ProjectType', 'Project', 'ProjectAssociation', 'Reporting',
    'CustomField', 'CustomFieldHelper',
    require('./timeline')
  ])
  .factory('TreeNode', require('./tree-node'))
  .factory('User', require('./user'));
