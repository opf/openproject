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

function WorkPackagesListController($scope,
                                    $rootScope,
                                    $state,
                                    $location,
                                    WorkPackagesTableService,
                                    WorkPackageService,
                                    wpListService,
                                    ProjectService,
                                    QueryService,
                                    PaginationService,
                                    AuthorisationService,
                                    UrlParamsHelper,
                                    OPERATORS_AND_LABELS_BY_FILTER_TYPE,
                                    loadingIndicator,
                                    inplaceEditAll,
                                    keepTab,
                                    I18n) {

  $scope.projectIdentifier = $state.params.projectPath || null;
  $scope.loadingIndicator = loadingIndicator;

  // Setup
  function initialSetup() {
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.disableFilters = false;
    $scope.disableNewWorkPackage = true;
    setupFiltersVisibility();
    $scope.toggleShowFilterOptions = function () {
      WorkPackagesTableService.toggleShowFilterOptions();
      setupFiltersVisibility();
    };

    loadingIndicator.mainPage = wpListService.fromQueryParams($state.params, $scope.projectIdentifier)
      .then((json:api.ex.WorkPackagesMeta) => {

        setupPage(json, !!$state.params.query_props);
        QueryService.loadAvailableUnusedColumns($scope.projectIdentifier).then(function (data) {
          $scope.availableUnusedColumns = data;
        });

        QueryService.loadAvailableGroupedQueries($scope.projectIdentifier);
        QueryService.loadAvailableUnusedColumns($scope.projectIdentifier).then(function(data) {
          $scope.availableUnusedColumns = data;
        });

        if ($scope.projectIdentifier) {
          ProjectService.getProject($scope.projectIdentifier).then(function (project) {
            $scope.project = project;
            $scope.projects = [project];
          });
        }
      });
  }

  function clearUrlQueryParams() {
    $location.search('query_props', null);
    $location.search('query_id', null);
  }

  function setupPage(json, queryParamsPresent) {
    // Init query
    var metaData = json.meta;
    var queryData = metaData.query;
    var columnData = metaData.columns;
    var cachedQuery = QueryService.getQuery();
    var urlQueryId = $state.params.query_id;

    if (cachedQuery && urlQueryId && cachedQuery.id == urlQueryId) {
      // Augment current unsaved query with url param data
      var updateData = angular.extend(queryData, {columns: columnData});
      $scope.query = QueryService.updateQuery(updateData, afterQuerySetupCallback);
    } else {
      // Set up fresh query from retrieved query meta data
      $scope.query = QueryService.initQuery($state.params.query_id, queryData, columnData,
        metaData.export_formats, afterQuerySetupCallback);

      if (queryParamsPresent) {
        $scope.query.dirty = true;
      }
    }

    $scope.maintainBackUrl();

    // setup table
    setupWorkPackagesTable(json);

    if (json.work_packages.length) {
      WorkPackageService.cache().put('preselectedWorkPackageId', json.work_packages[0].id);
    }
  }

  function afterQuerySetupCallback() {
    setupFiltersVisibility();
  }

  function setupWorkPackagesTable(json) {
    var meta = json.meta,
      workPackages = json.work_packages,
      bulkLinks = json._bulk_links;

    // register data

    // table data
    WorkPackagesTableService.setColumns($scope.query.columns);
    WorkPackagesTableService.addColumnMetaData(meta);
    WorkPackagesTableService.setGroupBy($scope.query.groupBy);
    WorkPackagesTableService.buildRows(workPackages, $scope.query.groupBy);
    WorkPackagesTableService.setBulkLinks(bulkLinks);

    // query data
    QueryService.setTotalEntries(json.resource.total);

    // pagination data
    PaginationService.setPerPageOptions(meta.per_page_options);
    PaginationService.setPerPage(meta.per_page);
    PaginationService.setPage(meta.page);

    // yield updatable data to scope
    $scope.columns = $scope.query.columns;
    $scope.rows = WorkPackagesTableService.getRows();
    $scope.groupableColumns = WorkPackagesTableService.getGroupableColumns();
    $scope.totalEntries = QueryService.getTotalEntries();
    $scope.resource = json.resource;

    // Authorisation
    AuthorisationService.initModelAuth("work_package", meta._links);
    AuthorisationService.initModelAuth("query", meta.query._links);
  }

  function setupFiltersVisibility() {
    $scope.showFiltersOptions = WorkPackagesTableService.getShowFilterOptions();
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
    // Clear unsaved changes to current query
    wpListService.clearUrlQueryParams();
    loadingIndicator.mainPage = $state.go('work-packages.list',
      {'query_id': queryId},
      {reload: true});
  };

  function updateResults() {
    $scope.$broadcast('openproject.workPackages.updateResults');

    loadingIndicator.mainPage = wpListService.fromQueryInstance($scope.query, $scope.projectIdentifier)
      .then(function (json:api.ex.WorkPackagesMeta) {
        setupWorkPackagesTable(json);
      });
  }

  // Go

  initialSetup();

  $scope.editAll = inplaceEditAll;

  $scope.$watch(QueryService.getQueryName, function (queryName) {
    $scope.selectedTitle = queryName || I18n.t('js.label_work_package_plural');
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

        var rowLookup = _.indexBy($scope.rows, (row:any) => row.object.id);

        // Merge based on id and lockVersion
        angular.forEach(json.work_packages, (fresh, i) => {
          var staleRow = rowLookup[fresh.id];
          if (staleRow && staleRow.object.lockVersion === fresh.lockVersion) {
            json.work_packages[i] = staleRow.object;
          }
        });

        $scope.$broadcast('openproject.workPackages.updateResults');
        $scope.$evalAsync(_ => setupWorkPackagesTable(json));
      });
  });

  $rootScope.$on('queryClearRequired', _ => wpListService.clearUrlQueryParams);
  $rootScope.$on('workPackgeLoaded', function () {
    wpListService.fromQueryInstance($scope.query, $scope.projectIdentifier)
      .then(function (json:api.ex.WorkPackagesMeta) {
        setupWorkPackagesTable(json);
      });
  });

  function nextAvailableWorkPackage() {
    var selected = WorkPackageService.cache().get('preselectedWorkPackageId');
    return selected || $scope.rows.first().object.id;
  }

  $scope.nextAvailableWorkPackage = nextAvailableWorkPackage;

  $scope.openWorkPackageInFullView = function (id, force) {
    if (force || $state.current.url != "") {
      loadingIndicator.mainPage = $state.go('work-packages.show', {
        workPackageId: id,
        query_props: $state.params.query_props
      });
    }
  };

  $scope.getFilterCount = function () {
    if ($scope.query) {
      var filters = $scope.query.filters;
      return _.size(_.where(filters, function (filter) {
        return !filter.deactivated;
      }));
    } else {
      return 0;
    }
  };
}

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackagesListController', WorkPackagesListController);
