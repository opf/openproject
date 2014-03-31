angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', '$window', 'WorkPackagesTableHelper', 'Query', 'Sortation', 'WorkPackageService', 'QueryService', 'PaginationService', 'INITIALLY_SELECTED_COLUMNS', 'OPERATORS_AND_LABELS_BY_FILTER_TYPE', 'DEFAULT_SORT_CRITERIA',
            function($scope, $window, WorkPackagesTableHelper, Query, Sortation, WorkPackageService, QueryService, PaginationService, INITIALLY_SELECTED_COLUMNS, OPERATORS_AND_LABELS_BY_FILTER_TYPE, DEFAULT_SORT_CRITERIA) {


  function setUrlParams(location) {
    $scope.projectIdentifier = location.pathname.split('/')[2];

    var regexp = /query_id=(\d+)/g;
    var match = regexp.exec(location.search);
    if(match) $scope.query_id = match[1];
  }

  function initialSetup() {
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.loading = false;
    $scope.disableFilters = false;

    $scope.withLoading(WorkPackageService.getWorkPackagesByQueryId, [$scope.projectIdentifier, $scope.query_id])
      .then($scope.setupWorkPackagesTable)
      .then(initAvailableColumns);
  }

  function initQuery(queryData) {
    $scope.query = new Query({
      id: $scope.queryId,
      displaySums: queryData.display_sums,
      groupSums: queryData.group_sums,
      sums: queryData.sums,
      filters: queryData.filters,
      columns: $scope.columns
    }); // TODO init sortation according to queryData

    sortation = new Sortation(DEFAULT_SORT_CRITERIA);
    $scope.query.setSortation(sortation);

    return $scope.query;
  }

  function initAvailableColumns() {
    return QueryService.getAvailableColumns($scope.projectIdentifier)
      .then(function(data){
        $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(data.available_columns, $scope.columns);
        return $scope.availableColumns;
      });
  }

  $scope.submitQueryForm = function(){
    jQuery("#selected_columns option").attr('selected',true);
    jQuery('#query_form').submit();
    return false;
  };

  $scope.setupWorkPackagesTable = function(json) {
    // TODO: We need to set the columns based on what's returned by the query for when we are loading using a query id.
    //       Also perhaps the filters... and everything:/
    var meta = json.meta;

    if (!$scope.columns) $scope.columns = meta.columns;
    if (!$scope.query) initQuery(meta.query);
    PaginationService.setPerPageOptions(meta.per_page_options);
    PaginationService.setPerPage(meta.per_page);
    PaginationService.setPage(meta.page);

    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.query.group_by);

    $scope.workPackageCountByGroup = meta.work_package_count_by_group;
    $scope.totalSums = meta.sums;
    $scope.groupSums = meta.group_sums;
    $scope.totalEntries = meta.total_entries;
  };

  $scope.updateResults = function() {
    return $scope.withLoading(WorkPackageService.getWorkPackages, [$scope.projectIdentifier, $scope.query, PaginationService.getPaginationOptions()])
      .then($scope.setupWorkPackagesTable);
  };

  function serviceErrorHandler(data) {
    // TODO RS: This is where we'd want to put an error message on the dom
    $scope.loading = false;
  }

  /**
   * @name withLoading
   *
   * @description Wraps a data-loading function and manages the loading state within the scope
   * @param {function} callback Function returning a promise
   * @param {array} params Params forwarded to the callback
   * @returns {promise} Promise returned by the callback
   */
  $scope.withLoading = function(callback, params){
    startedLoading();
    return callback.apply(this, params)
      .then(function(data){
        finishedLoading();
        return data;
      }, serviceErrorHandler);
  };

  function startedLoading() {
    $scope.loading = true;
  };

  function finishedLoading() {
    $scope.loading = false;
  };

  setUrlParams($window.location);
  initialSetup();
}]);
