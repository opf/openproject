angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', 'Query', 'Sortation', 'WorkPackageService', 'QueryService', 'INITIALLY_SELECTED_COLUMNS', 'OPERATORS_AND_LABELS_BY_FILTER_TYPE', 'AVAILABLE_WORK_PACKAGE_FILTERS','DEFAULT_SORT_CRITERIA', 'DEFAULT_QUERY', 'PAGINATION_OPTIONS',
            function($scope, WorkPackagesTableHelper, Query, Sortation, WorkPackageService, QueryService, INITIALLY_SELECTED_COLUMNS, OPERATORS_AND_LABELS_BY_FILTER_TYPE, AVAILABLE_WORK_PACKAGE_FILTERS, DEFAULT_SORT_CRITERIA, DEFAULT_QUERY, PAGINATION_OPTIONS) {

  function initialSetup() {
    $scope.projectIdentifier = gon.project_identifier;
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.loading = false;
    $scope.disableFilters = false;

    setupColumns();
  }

  function setupColumns(){
    $scope.columns = [];

    QueryService.getAvailableColumns($scope.projectIdentifier).then(function(data){
      $scope.columns = WorkPackagesTableHelper.getColumnUnionByName(data.available_columns, INITIALLY_SELECTED_COLUMNS);
      $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(data.available_columns, $scope.columns);
      return $scope.availableColumns;
    })
      .then(setupQuery)
      .then(setupPagination)
      .then($scope.updateResults);
  }

  function setupQuery() {
    $scope.query = new Query(DEFAULT_QUERY, { available_work_package_filters: AVAILABLE_WORK_PACKAGE_FILTERS});

    sortation = new Sortation(DEFAULT_SORT_CRITERIA);
    $scope.query.setSortation(sortation);
    $scope.currentSortation = DEFAULT_SORT_CRITERIA;
    angular.extend($scope.query, {
      selectedColumns: $scope.columns
    });
  }

  function setupPagination(json) {
    meta = json || PAGINATION_OPTIONS;
    $scope.paginationOptions = {
      page: meta.page,
      perPage: meta.per_page
    };
    $scope.perPageOptions = meta.per_page_options;
  }

  $scope.submitQueryForm = function(){
    jQuery("#selected_columns option").attr('selected',true);
    jQuery('#query_form').submit();
    return false;
  };

  $scope.setupWorkPackagesTable = function(json) {
    var meta = json.meta;
    $scope.workPackageCountByGroup = meta.work_package_count_by_group;
    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.query.group_by);
    $scope.totalSums = meta.sums;
    $scope.groupSums = meta.group_sums;
    $scope.totalEntries = meta.total_entries;

    setupPagination(meta);
  };

  $scope.updateResults = function() {
    $scope.withLoading(WorkPackageService.getWorkPackages, [$scope.projectIdentifier, $scope.query, $scope.paginationOptions])
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

  initialSetup();
}]);
