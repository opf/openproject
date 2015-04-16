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

angular.module('openproject.workPackages.services')
  .service('WorkPackagesTableService', [
    '$filter',
    'QueryService',
    'WorkPackagesTableHelper',
    require('./work-packages-table-service')
  ])
  .constant('WORK_PACKAGE_ATTRIBUTES', [
    {
      groupName: 'details',
      attributes: ['type', 'status', 'percentageDone', 'date', 'priority', 'version', 'category']
    },
    {
      groupName: 'people',
      attributes: ['assignee', 'responsible']
    },
    {
      groupName: 'estimatesAndTime',
      attributes: ['estimatedTime', 'spentTime']
    },
    {
      groupName: 'other',
      attributes: []
    }
  ])
  .constant('WORK_PACKAGE_REGULAR_EDITABLE_FIELD', [
    'assignee', 'responsible', 'status', 'version', 'priority'
  ])
  .service('WorkPackagesOverviewService', [
    'WORK_PACKAGE_ATTRIBUTES',
    require('./work-packages-overview-service')
  ])
  .service('WorkPackageFieldService', [
    'I18n',
    'WORK_PACKAGE_REGULAR_EDITABLE_FIELD',
    'WorkPackagesHelper',
    '$q',
    '$http',
    'HookService',
    'EditableFieldsState',
    require('./work-package-field-service')
  ])
  .service('EditableFieldsState',
    require('./editable-fields-state')
  );
