//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

.controller('WorkPackagesController', [
    '$scope',
    '$rootScope',
    '$q',
    '$window',
    '$location',
    'I18n',
    'ProjectService',
    'WorkPackagesTableService',
    'WorkPackageService',
    'QueryService',
    'PaginationService',
    'WorkPackageLoadingHelper',
    'INITIALLY_SELECTED_COLUMNS',
    'OPERATORS_AND_LABELS_BY_FILTER_TYPE',
    function($scope, $rootScope, $q, $window, $location, I18n, ProjectService,
      WorkPackagesTableService,
      WorkPackageService, QueryService, PaginationService,
      WorkPackageLoadingHelper, INITIALLY_SELECTED_COLUMNS,
      OPERATORS_AND_LABELS_BY_FILTER_TYPE) {

  // Setup

  function initialSetup() {
    setupPageParamsFromUrl($window.location);
    initProject();

    $scope.selectedTitle = I18n.t('js.toolbar.unselected_title');
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.loading = false;
    $scope.disableFilters = false;

    var getWorkPackages, params;
    if($location.search()['c[]']){
      getWorkPackages = WorkPackageService.getWorkPackagesFromUrlQueryParams;
      params = [$scope.projectIdentifier, $location];
    } else {
      getWorkPackages = WorkPackageService.getWorkPackagesByQueryId;
      params = [$scope.projectIdentifier, $scope.query_id];
    }

    $scope.withLoading(getWorkPackages, params)
      .then(setupPage);
  }

  function setupPageParamsFromUrl(location) {
    var normalisedPath = location.pathname.replace($window.appBasePath, '');

    $scope.projectIdentifier = normalisedPath.split('/')[2];
    $scope.$root.projectIdentifier = $scope.projectIdentifier; // temporary solution to share project identifier

    var regexp = /query_id=(\d+)/g;
    var match = regexp.exec(location.search);
    if(match) $scope.query_id = match[1];
  }


  function initProject() {
    if ($scope.projectIdentifier) {
      ProjectService.getProject($scope.projectIdentifier).then(function(project) {
        $scope.project  = project;
        $scope.projects = [ $scope.project ];
        $scope.availableTypes = $scope.project.embedded.types;
      });
    } else {
      ProjectService.getProjects().then(function(projects) {
        var allTypes, availableTypes;

        $scope.projects = projects;
        allTypes = projects.map(function(project) {
          return project.embedded.types;
        }).reduce(function(a, b) {
          return a.concat(b);
        }, []);

        $scope.availableTypes = allTypes; // TODO remove duplicates
      });
    }
  }

  function setupPage(json) {
    initQuery(json.meta);
    setupWorkPackagesTable(json);

    return $q.all([
      initAvailableColumns(),
      initAvailableQueries()
    ]);
  }

  function initQuery(metaData) {
    var queryData = metaData.query,
        columnData = metaData.columns;

    $scope.query = QueryService.getQuery() || QueryService.initQuery($scope.query_id, queryData, columnData, afterQuerySetupCallback);
  }

  function afterQuerySetupCallback(query) {
    $scope.showFiltersOptions = query.filters.length > 0;
    $scope.updateBackUrl();
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

    // back url
    $scope.updateBackUrl();
  }

  function initAvailableColumns() {
    return QueryService.loadAvailableUnusedColumns($scope.projectIdentifier)
      .then(function(data){
        $scope.availableUnusedColumns = data;
      });
  }

  function initAvailableQueries() {
    QueryService.loadAvailableGroupedQueries($scope.projectIdentifier);

    $scope.availableOptions = QueryService.getAvailableOptions(); // maybe generalize this approach
  }

  $scope.$watch('availableOptions.availableGroupedQueries', function(availableQueries) {
    if (availableQueries) {
      $scope.groups = [{ name: 'CUSTOM QUERIES', models: availableQueries['user_queries']},
                       { name: 'GLOBAL QUERIES', models: availableQueries['queries']}];
    }
  });

  // Updates

  $scope.reloadQuery = function(queryId) {
    QueryService.resetQuery();
    $scope.query_id = queryId;

    $scope.withLoading(WorkPackageService.getWorkPackagesByQueryId, [$scope.projectIdentifier, $scope.query_id])
      .then(setupPage);
  };

  $scope.updateBackUrl = function(){
    // Easier than trying to extract it from $location
    var relativeUrl = "/work_packages";
    if ($scope.projectIdentifier){
      relativeUrl = "/projects/" + $scope.projectIdentifier + relativeUrl;
    }

    if($scope.query){
      relativeUrl = relativeUrl + "#?" + $scope.query.getQueryString();
    }

    $scope.backUrl = relativeUrl;
  };

  $scope.updateResults = function() {
    $scope.$broadcast('openproject.workPackages.updateResults');

    return $scope.withLoading(WorkPackageService.getWorkPackages, [$scope.projectIdentifier, $scope.query, PaginationService.getPaginationOptions()])
      .then(setupWorkPackagesTable);
  };

  // More

  function serviceErrorHandler(data) {
    // TODO RS: This is where we'd want to put an error message on the dom
    $scope.isLoading = false;
  }

  $scope.withLoading = function(callback, params){
    return WorkPackageLoadingHelper.withLoading($scope, callback, params, serviceErrorHandler);
  };

  // Go

  initialSetup();

  // Note: I know we don't want watchers on the controller but I want all the toolbar directives to have restricted scopes. Thoughts welcome.
  $scope.$watch('query.name', function(newValue, oldValue){
    if(newValue != oldValue && $scope.query.hasName()){
      $scope.selectedTitle = newValue;
    }
  });

  $rootScope.$on('queryResetRequired', function(event, message) {
    $scope.query_id = null;
    initialSetup();
  });

}]);
