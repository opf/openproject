angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', 'Query', 'Sortation', 'WorkPackageService', 'QueryService', 'PaginationService', 'INITIALLY_SELECTED_COLUMNS', 'OPERATORS_AND_LABELS_BY_FILTER_TYPE', 'AVAILABLE_WORK_PACKAGE_FILTERS','DEFAULT_SORT_CRITERIA', 'DEFAULT_QUERY',
            function($scope, WorkPackagesTableHelper, Query, Sortation, WorkPackageService, QueryService, PaginationService, INITIALLY_SELECTED_COLUMNS, OPERATORS_AND_LABELS_BY_FILTER_TYPE, AVAILABLE_WORK_PACKAGE_FILTERS, DEFAULT_SORT_CRITERIA, DEFAULT_QUERY) {


  function initialSetup() {
    $scope.projectIdentifier = gon.project_identifier;
    if(gon.query_id) $scope.query_id = gon.query_id;

    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.loading = false;
    $scope.disableFilters = false;

    setupColumns()
      .then(setupQuery)
      .then($scope.updateResults)
      .then(setupComplete);

  }

  function setupColumns(){
    $scope.columns = [];

    return QueryService.getAvailableColumns($scope.projectIdentifier)
      .then(function(data){
        $scope.columns = WorkPackagesTableHelper.getColumnUnionByName(data.available_columns, INITIALLY_SELECTED_COLUMNS);
        $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(data.available_columns, $scope.columns);
        return $scope.availableColumns;
      });
  }

  function setupQuery() {
    var query = DEFAULT_QUERY;
    if($scope.query_id){
      angular.extend(query, { id: $scope.query_id });
    }
    $scope.query = new Query(query, { available_work_package_filters: AVAILABLE_WORK_PACKAGE_FILTERS});

    sortation = new Sortation(DEFAULT_SORT_CRITERIA);
    $scope.query.setSortation(sortation);
    $scope.currentSortation = DEFAULT_SORT_CRITERIA;
    angular.extend($scope.query, {
      selectedColumns: $scope.columns
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
    $scope.workPackageCountByGroup = meta.work_package_count_by_group;
    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.query.group_by);
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

  function setupComplete() {
    $scope.setupComplete = true;
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

  initialSetup();
}]);
