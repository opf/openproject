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

angular.module('openproject.workPackages.directives')
  .directive('langAttribute', require('./lang-attribute-directive'))
  .directive('queryColumns', [
    'WorkPackagesTableHelper',
    'WorkPackagesTableService',
    'WorkPackageService',
    'QueryService', require('./query-columns-directive')
  ])
  .directive('queryFilter', [
    'WorkPackageLoadingHelper',
    'QueryService',
    'PaginationService',
    'I18n',
    'OPERATORS_NOT_REQUIRING_VALUES',
    '$timeout',
    '$animate', require('./query-filter-directive')
  ])
  .constant('ADD_FILTER_SELECT_INDEX', -1)
  .directive('queryFilters', [
    '$timeout',
    'FiltersHelper',
    'I18n',
    'ADD_FILTER_SELECT_INDEX', require('./query-filters-directive')
  ])
  .directive('queryForm', require('./query-form-directive'))
  .directive('sortHeader', [
    'I18n', require('./sort-header-directive')
  ])
  .directive('workPackageColumn', ['PathHelper', 'WorkPackagesHelper',
    'UserService',
    require('./work-package-column-directive')
  ])
  .directive('workPackageField', require('./work-package-field-directive'))
  .constant('PERMITTED_MORE_MENU_ACTIONS', ['log_time', 'duplicate', 'move',
    'delete'
  ])
  .directive('workPackageDetailsToolbar', [
    'PERMITTED_MORE_MENU_ACTIONS',
    '$state',
    '$window',
    '$location',
    'I18n',
    'HookService',
    'WorkPackageService',
    'WorkPackageAuthorization',
    'PathHelper',
    require('./work-package-details-toolbar-directive')
  ])
  .directive('workPackageDynamicAttribute', ['$compile', require(
    './work-package-dynamic-attribute-directive')])
  .directive('workPackageGroupHeader', require(
    './work-package-group-header-directive'))
  .directive('workPackageGroupSums', require(
    './work-package-group-sums-directive'))
  .directive('workPackageRow', ['I18n', 'WorkPackagesTableService', require(
    './work-package-row-directive')])
  .directive('workPackageTotalSums', [
    'WorkPackageService',
    require('./work-package-total-sums-directive')
  ])
  .directive('workPackagesTable', [
    'I18n',
    'WorkPackagesTableService',
    '$window',
    '$timeout',
    'featureFlags',
    'PathHelper',
    require('./work-packages-table-directive')
  ]);

  require('./inplace_editor');
  require('./inplace_editor/custom/display');
  require('./inplace_editor/custom/editable');
