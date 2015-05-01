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

angular.module('openproject.workPackages.helpers')
  .factory('ApiHelper', require('./api-helper'))
  .factory('FiltersHelper', ['I18n', require('./filters-helper')])
  .constant('ACTIVE_USER_STATUSES', ['active', 'registered'])
  .factory('UsersHelper', ['ACTIVE_USER_STATUSES', require('./users-helper')])
  .constant('PERMITTED_BULK_ACTIONS', ['edit', 'watch', 'move', 'copy',
    'delete'
  ])
  .service('WorkPackageContextMenuHelper', ['PERMITTED_BULK_ACTIONS',
    'WorkPackagesTableService', 'UrlParamsHelper', require(
      './work-package-context-menu-helper')
  ])
  .factory('WorkPackagesHelper', ['TimezoneService', 'currencyFilter',
    'CustomFieldHelper', require('./work-packages-helper')
  ])
  .factory('WorkPackagesTableHelper', ['WorkPackagesHelper', require(
    './work-packages-table-helper')]);
