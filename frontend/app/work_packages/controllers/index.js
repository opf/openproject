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

angular.module('openproject.workPackages.controllers')
  .constant('TEXT_TYPE', 'text')
  .constant('STATUS_TYPE', 'status')
  .constant('VERSION_TYPE', 'version')
  .constant('CATEGORY_TYPE', 'category')
  .constant('PRIORITY_TYPE', 'priority')
  .constant('USER_TYPE', 'user')
  .constant('TIME_ENTRY_TYPE', 'time_entry')
  .constant('USER_FIELDS', ['assignee', 'author', 'responsible'])
  .controller('DetailsTabOverviewController', [
    '$scope',
    'WorkPackagesOverviewService',
    'WorkPackageFieldService',
    require('./details-tab-overview-controller')
  ])
  .constant('ADD_WATCHER_SELECT_INDEX', -1)
  .controller('DetailsTabWatchersController', ['$scope',
    '$filter',
    '$timeout',
    'I18n',
    'ADD_WATCHER_SELECT_INDEX', require('./details-tab-watchers-controller')
  ])
  .constant('RELATION_TYPES', {
    relatedTo: "Relation::Relates",
    duplicates: "Relation::Duplicates",
    duplicated: "Relation::Duplicated",
    blocks: "Relation::Blocks",
    blocked: "Relation::Blocked",
    precedes: "Relation::Precedes",
    follows: "Relation::Follows"
  })
  .constant('RELATION_IDENTIFIERS', {
    parent: "parent",
    relatedTo: "relates",
    duplicates: "duplicates",
    duplicated: "duplicated",
    blocks: "blocks",
    blocked: "blocked",
    precedes: "precedes",
    follows: "follows"
  })
  .controller('WorkPackageDetailsController', [
    '$scope',
    '$state',
    'latestTab',
    'workPackage',
    'I18n',
    'RELATION_TYPES',
    'RELATION_IDENTIFIERS',
    '$q',
    'WorkPackagesHelper',
    'PathHelper',
    'UsersHelper',
    'ConfigurationService',
    'WorkPackageService',
    'CommonRelationsHandler',
    'ChildrenRelationsHandler',
    'ParentRelationsHandler',
    'EditableFieldsState',
    require('./work-package-details-controller')
  ])
  .controller('WorkPackagesController', [
    '$scope',
    '$state',
    '$stateParams',
    'QueryService',
    'PathHelper',
    '$rootScope',
    require('./work-packages-controller')
  ])
  .controller('WorkPackagesListController', [
    '$scope',
    '$rootScope',
    '$state',
    '$location',
    'latestTab',
    'I18n',
    'WorkPackagesTableService',
    'WorkPackageService',
    'ProjectService',
    'QueryService',
    'PaginationService',
    'AuthorisationService',
    'UrlParamsHelper',
    'PathHelper',
    'Query',
    'OPERATORS_AND_LABELS_BY_FILTER_TYPE',
    require('./work-packages-list-controller')
  ])
  .factory('columnsModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'ColumnsModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/columns.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('ColumnsModalController', ['$scope',
    '$filter',
    'columnsModal',
    'QueryService',
    'WorkPackageService',
    'WorkPackagesTableService',
    '$rootScope',
    '$timeout',
    require('./dialogs/columns')
  ])
  .factory('exportModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'ExportModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/export.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('ExportModalController', ['exportModal', 'QueryService',
    'UrlParamsHelper',
    require('./dialogs/export')
  ])
  .factory('groupingModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'GroupByModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/group_by.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('GroupByModalController', [
    '$scope',
    '$filter',
    'groupingModal',
    'QueryService',
    'WorkPackagesTableService',
    'I18n',
    require('./dialogs/group-by')
  ])
  .factory('saveModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'SaveModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/save.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('SaveModalController', [
    '$scope',
    'saveModal',
    'QueryService',
    'AuthorisationService',
    '$state',
    require('./dialogs/save')
  ])
  .factory('settingsModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'SettingsModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/settings.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('SettingsModalController', [
    '$scope',
    'settingsModal',
    'QueryService',
    'AuthorisationService',
    '$rootScope',
    'QUERY_MENU_ITEM_TYPE',
    require('./dialogs/settings')
  ])
  .factory('shareModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'ShareModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/share.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('ShareModalController', [
    '$scope',
    'shareModal',
    'QueryService',
    'AuthorisationService',
    'queryMenuItemFactory',
    'PathHelper',
    require('./dialogs/share')
  ])
  .factory('sortingModal', ['btfModal', function(btfModal) {
    return btfModal({
      controller: 'SortingModalController',
      controllerAs: 'modal',
      templateUrl: '/templates/work_packages/modals/sorting.html',
      afterFocusOn: '#work-packages-settings-button'
    });
  }])
  .controller('SortingModalController', ['sortingModal',
    '$scope',
    '$filter',
    'QueryService',
    'I18n',
    require('./dialogs/sorting')
  ]);
require('./menus');
