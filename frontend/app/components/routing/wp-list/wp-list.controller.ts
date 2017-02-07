// -- copyright
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
// ++

import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {ErrorResource} from '../../api/api-v3/hal-resources/error-resource.service';
import {States} from '../../states.service';
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';
import { Observable } from 'rxjs/Observable';
import {LoadingIndicatorService} from '../../common/loading-indicator/loading-indicator.service';
import {WorkPackageTableMetadata} from '../../wp-fast-table/wp-table-metadata';

function WorkPackagesListController($scope,
                                    $rootScope,
                                    $state,
                                    $location,
                                    $q,
                                    states:States,
                                    wpNotificationsService:WorkPackageNotificationService,
                                    wpTableColumns:WorkPackageTableColumnsService,
                                    WorkPackageService,
                                    wpListService,
                                    wpCacheService:WorkPackageCacheService,
                                    ProjectService,
                                    QueryService,
                                    PaginationService,
                                    AuthorisationService,
                                    UrlParamsHelper,
                                    OPERATORS_AND_LABELS_BY_FILTER_TYPE,
                                    loadingIndicator:LoadingIndicatorService,
                                    I18n) {

  $scope.projectIdentifier = $state.params.projectPath || null;
  $scope.I18n = I18n;
  $scope.text = {
    'jump_to_pagination': I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': I18n.t('js.work_packages.jump_marks.label_pagination')
  };

  // Setup
  function initialSetup() {
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.disableFilters = false;
    $scope.disableNewWorkPackage = true;
    $scope.queryError = false;

    loadingIndicator.table.promise = wpListService.fromQueryParams($state.params, $scope.projectIdentifier)
      .then((json:api.ex.WorkPackagesMeta) => {

        // Update work package states
        wpCacheService.updateWorkPackageList(json.work_packages);
        setupPage(json);
      })
      .catch((result:{ error: ErrorResource|any , json: api.ex.WorkPackagesMeta }) => {
        wpNotificationsService.handleErrorResponse(result.error);
        setupPage(result.json);
        $scope.query.hasError = true;
      });
  }

  function setupQuery(json) {
    QueryService.loadAvailableGroupedQueries($scope.projectIdentifier);
    QueryService.loadAvailableUnusedColumns($scope.projectIdentifier);

    var metaData = json.meta;
    var queryData = metaData.query;
    var columnData = metaData.columns;
    var cachedQuery = QueryService.getQuery();
    var urlQueryId = $state.params.query_id;


    // Set current column state
    states.table.columns.put(metaData.columns.map(column => column.name));

    if (cachedQuery && urlQueryId && cachedQuery.id === urlQueryId) {
      // Augment current unsaved query with url param data
      var updateData = angular.extend(queryData, {columns: columnData});
      $scope.query = QueryService.updateQuery(updateData);
    } else {
      // Set up fresh query from retrieved query meta data
      $scope.query = QueryService.initQuery(
        $state.params.query_id, queryData, columnData, metaData.export_formats);

      if (!!$state.params.query_props) {
        $scope.query.dirty = true;
      }
    }
  }

  function loadProject() {
    if ($scope.projectIdentifier) {
      ProjectService.getProject($scope.projectIdentifier).then(function (project) {
        $scope.project = project;
        $scope.projects = [project];
      });
    }
  }

  function setupPage(json) {
    // Init query
    setupQuery(json);

    // Load project
    loadProject();

    $scope.maintainBackUrl();

    // setup table
    setupWorkPackagesTable(json);
  }

  function setupWorkPackagesTable(json) {

    // Set metadata from results
    let meta = json.meta;
    let metadata = new WorkPackageTableMetadata(json);

    // pagination data
    PaginationService.setPerPageOptions(meta.per_page_options);
    PaginationService.setPerPage(meta.per_page);
    PaginationService.setPage(meta.page);

    // Update the current metadata state
    states.table.metadata.put(metadata);

    // register data in state
    $q.all(json.work_packages.map(wp => wp.schema.$load())).then(() => {
      states.table.rows.put(json.work_packages);
    });

    // query data
    // QueryService.setTotalEntries(json.resource.total);

    // yield updatable data to scope
    Observable.combineLatest(
      states.table.columns.observe(null),
      states.query.availableColumns.observe(null)
    ).subscribe(() => {
      $scope.columns = wpTableColumns.getColumns();
    });

    // $scope.totalEntries = QueryService.getTotalEntries();
    $scope.resource = json.resource;
    $scope.rowcount = json.resource.count;
    // $scope.groupHeaders = WorkPackagesTableService.buildGroupHeaders(json.resource);

    // Authorisation
    AuthorisationService.initModelAuth('work_package', meta._links);
    AuthorisationService.initModelAuth('query', meta.query._links);
  }

  $scope.setAnchorToNextElement = function () {
    // Skip to next when visible, otherwise skip to previous
    const selectors = '#pagination--next-link, #pagination--prev-link, #pagination-empty-text';
    const visibleLink = jQuery(selectors)
                          .not(':hidden')
                          .first();

   if (visibleLink.length) {
     visibleLink.focus();
   }
  }

  $scope.maintainBackUrl = function () {
    $scope.backUrl = $location.url();
  };

  // Updates

  $scope.maintainUrlQueryState = function () {
    if ($scope.query) {
      $location.search('query_props', UrlParamsHelper.encodeQueryJsonParams($scope.query));
    }
  };

  $scope.loadQuery = function (queryId) {
    loadingIndicator.table.promise= $state.go('work-packages.list',
      {'query_id': queryId,
       'query_props': null});
  };

  function updateResults() {
    $scope.$broadcast('openproject.workPackages.updateResults');

    loadingIndicator.table.promise = wpListService.fromQueryInstance($scope.query, $scope.projectIdentifier)
      .then(function (json:api.ex.WorkPackagesMeta) {
        wpCacheService.updateWorkPackageList(json.work_packages);
        setupWorkPackagesTable(json);
      });
  }

  // Go

  initialSetup();

  $scope.$watch(QueryService.getQueryName, function (queryName) {
    $scope.selectedTitle = queryName || I18n.t('js.label_work_package_plural');
  });

  $scope.$watchCollection(function(){
    return {
      query_id: $state.params.query_id,
      query_props: $state.params.query_props
    };
  }, function(params) {
    if ($scope.query &&
        (params.query_id !== $scope.query.id ||
         UrlParamsHelper.encodeQueryJsonParams($scope.query) !== params.query_props)) {
      initialSetup();
    }
  });

  $rootScope.$on('queryStateChange', function () {
    $scope.maintainUrlQueryState();
    $scope.maintainBackUrl();
  });

  $rootScope.$on('workPackagesRefreshRequired', function () {
    updateResults();
  });

  $rootScope.$on('workPackagesRefreshInBackground', function () {
    wpListService.fromQueryInstance($scope.query, $scope.projectIdentifier)
      .then(function (json:api.ex.WorkPackagesMeta) {
        $scope.$broadcast('openproject.workPackages.updateResults');
        $scope.$evalAsync(_ => setupWorkPackagesTable(json));
      });
  });

  $rootScope.$on('queryClearRequired', _ => wpListService.clearUrlQueryParams);
}

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackagesListController', WorkPackagesListController);
