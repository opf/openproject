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
    '$q',
    '$window',
    '$location',
    'WorkPackagesTableHelper',
    'WorkPackagesTableService',
    'WorkPackageService',
    'QueryService',
    'PaginationService',
    'WorkPackageLoadingHelper',
    'INITIALLY_SELECTED_COLUMNS',
    'OPERATORS_AND_LABELS_BY_FILTER_TYPE',
    function($scope, $q, $window, $location,
      WorkPackagesTableHelper, WorkPackagesTableService,
      WorkPackageService, QueryService, PaginationService,
      WorkPackageLoadingHelper, INITIALLY_SELECTED_COLUMNS,
      OPERATORS_AND_LABELS_BY_FILTER_TYPE) {

  $scope.projectTypes = $window.gon.project_types;
  $scope.showFiltersOptions = false;


  // Setup

  function initialSetup() {
    setUrlParams($window.location);

    $scope.selectedTitle = "Work Packages";
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

  function setUrlParams(location) {
    var normalisedPath = location.pathname.replace($window.appBasePath, '');
    $scope.projectIdentifier = normalisedPath.split('/')[2];

    var regexp = /query_id=(\d+)/g;
    var match = regexp.exec(location.search);
    if(match) $scope.query_id = match[1];
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
    $scope.showFilters = query.filters.length > 0;
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
    WorkPackagesTableService.setRows(WorkPackagesTableHelper.getRows(workPackages, $scope.query.groupBy));
    WorkPackagesTableService.setGroupBy($scope.query.groupBy);
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
    return QueryService.getAvailableUnusedColumns($scope.projectIdentifier)
      .then(function(data){
        $scope.availableUnusedColumns = data;
      });
  }

  function initAvailableQueries() {
    return QueryService.getAvailableGroupedQueries($scope.projectIdentifier)
      .then(function(data){
        $scope.groups = [{ name: 'CUSTOM QUERIES', models: data["user_queries"]},
          { name: 'GLOBAL QUERIES', models: data["queries"]}];
      });
  }

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

  $scope.submitQueryForm = function(){
    jQuery("#selected_columns option").attr('selected',true);
    jQuery('#query_form').submit();
    return false;
  };

  // Go

  initialSetup();

  // Note: I know we don't want watchers on the controller but I want all the toolbar directives to have restricted scopes. Thoughts welcome.
  $scope.$watch('query.name', function(newValue, oldValue){
    if(newValue != oldValue && $scope.query.hasName()){
      $scope.selectedTitle = newValue;
    }
  });

}]);
