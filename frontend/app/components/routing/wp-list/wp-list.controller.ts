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
                                    apiWorkPackages,
                                    ProjectService,
                                    QueryService,
                                    PaginationService,
                                    AuthorisationService,
                                    UrlParamsHelper,
                                    Query,
                                    OPERATORS_AND_LABELS_BY_FILTER_TYPE,
                                    NotificationsService,
                                    loadingIndicator,
                                    inplaceEditAll,
                                    keepTab,
                                    I18n) {

  $scope.projectIdentifier = $state.params.projectPath || null;
  $scope.loadingIndicator = loadingIndicator;

  //TODO: Move this somewhere else
  var propertyMap = {
    assigned_to: 'assignee',
    updated_at: 'updatedAt'
  };
  var mapColumns = columns => columns.forEach(column => {
    //noinspection TypeScriptUnresolvedVariable
    column.name = propertyMap[column.name] || column.name;
  });

  // Setup
  function initialSetup() {
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.disableFilters = false;
    $scope.disableNewWorkPackage = true;
    setupFiltersVisibility();
    $scope.toggleShowFilterOptions = function() {
      WorkPackagesTableService.toggleShowFilterOptions();
      setupFiltersVisibility();
    };

    var queryParams = $state.params.query_props;
    var fetchWorkPackages;

    if(queryParams) {
      try {
        var queryData = UrlParamsHelper.decodeQueryFromJsonParams($state.params.query_id, queryParams);
        var queryFromParams = new Query(queryData, { rawFilters: true });

        // Set pagination options if present
        if(!!queryFromParams.page) {
          PaginationService.setPage(queryFromParams.page);
        }
        if(!!queryFromParams.perPage) {
          PaginationService.setPerPage(queryFromParams.perPage);
        }

        fetchWorkPackages = WorkPackageService.getWorkPackages(
          $scope.projectIdentifier, queryFromParams, PaginationService.getPaginationOptions());

      } catch(e) {
        NotificationsService.addError(
          I18n.t('js.work_packages.query.errors.unretrievable_query')
        );
        clearUrlQueryParams();

        fetchWorkPackages = WorkPackageService.getWorkPackages($scope.projectIdentifier);
      }

    } else if($state.params.query_id) {
      // Load the query by id if present
      fetchWorkPackages = WorkPackageService.getWorkPackagesByQueryId(
        $scope.projectIdentifier, $state.params.query_id);

    } else {
      // Clear the cached query and load the default
      QueryService.clearQuery();
      fetchWorkPackages = WorkPackageService.getWorkPackages($scope.projectIdentifier);
    }

    //TODO: Move this call and everything that belongs to it to the meta service
    loadingIndicator.mainPage = fetchWorkPackages.then(function(json:api.ex.WorkPackagesMeta) {
      mapColumns(json.meta.columns);

      apiWorkPackages.list(json.meta.columns).then(function(workPackages) {
        json.work_packages = workPackages;
        setupPage(json, !!queryParams);
      });

      QueryService.loadAvailableUnusedColumns($scope.projectIdentifier).then(function(data){
        $scope.availableUnusedColumns = data;
      });

      if ($scope.projectIdentifier) {
        ProjectService.getProject($scope.projectIdentifier).then(function(project) {
          $scope.project = project;
          $scope.projects = [ project ];
        });
      }

      QueryService.loadAvailableGroupedQueries($scope.projectIdentifier);
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
      var updateData = angular.extend(queryData, { columns: columnData });
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
    QueryService.setTotalEntries(meta.total_entries);

    // pagination data
    PaginationService.setPerPageOptions(meta.per_page_options);
    PaginationService.setPerPage(meta.per_page);
    PaginationService.setPage(meta.page);

    // yield updatable data to scope
    $scope.columns = $scope.query.columns;
    $scope.rows = WorkPackagesTableService.getRows();
    $scope.groupableColumns = WorkPackagesTableService.getGroupableColumns();
    $scope.workPackageCountByGroup = meta.work_package_count_by_group;
    $scope.totalEntries = QueryService.getTotalEntries();

    // Authorisation
    AuthorisationService.initModelAuth("work_package", meta._links);
    AuthorisationService.initModelAuth("query", meta.query._links);
  }

  function setupFiltersVisibility() {
    $scope.showFiltersOptions = WorkPackagesTableService.getShowFilterOptions();
  }

  $scope.maintainBackUrl = function() {
    $scope.backUrl = $location.url();
  };

  // Updates

  $scope.maintainUrlQueryState = function(){
    if($scope.query) {
      $location.search('query_props', UrlParamsHelper.encodeQueryJsonParams($scope.query));
    }
  };

  $scope.loadQuery = function(queryId) {
    // Clear unsaved changes to current query
    clearUrlQueryParams();
    loadingIndicator.mainPage = $state.go('work-packages.list',
                                          { 'query_id': queryId },
                                          { reload: true });
  };

  function updateResults() {
    $scope.$broadcast('openproject.workPackages.updateResults');

    //TODO: Move this to the WP meta service (see TODO above)
    loadingIndicator.mainPage = WorkPackageService.getWorkPackages($scope.projectIdentifier,
      $scope.query, PaginationService.getPaginationOptions())
      .then(function (json:api.ex.WorkPackagesMeta) {
        apiWorkPackages.list().then(function (workPackages) {
          json.work_packages = workPackages;
          setupWorkPackagesTable(json);
        })
      });
  }

  // Go

  initialSetup();

  $scope.editAll = inplaceEditAll;

  $scope.$watch(QueryService.getQueryName, function(queryName){
    $scope.selectedTitle = queryName || I18n.t('js.label_work_package_plural');
  });

  $rootScope.$on('queryStateChange', function() {
    $scope.maintainUrlQueryState();
    $scope.maintainBackUrl();
  });

  $rootScope.$on('workPackagesRefreshRequired', function() {
    updateResults();
  });

  $rootScope.$on('queryClearRequired', function() {
    $location.search('query_props', null);

    if($location.search().query_id) {
      $location.search('query_id', null);

    } else {
      initialSetup();
    }
  });

  $rootScope.$on('workPackgeLoaded', function() {
    $scope.maintainBackUrl();
  });

  function nextAvailableWorkPackage() {
    var selected = WorkPackageService.cache().get('preselectedWorkPackageId');
    return selected || $scope.rows.first().object.id;
  }

  $scope.nextAvailableWorkPackage = nextAvailableWorkPackage;

  $scope.showWorkPackageDetails = function(id, force) {
    if (force || $state.current.url != "") {
      loadingIndicator.mainPage = $state.go(keepTab.currentDetailsTab, {
        workPackageId: id,
        query_props: $state.params.query_props
      });
    }
  };

  $scope.getFilterCount = function() {
    if ($scope.query) {
      var filters = $scope.query.filters;
      return _.size(_.where(filters, function(filter) {
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
