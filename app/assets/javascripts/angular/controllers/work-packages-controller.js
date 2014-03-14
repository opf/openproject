angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', 'Query', 'Sortation', 'WorkPackageService', 'AVAILABLE_COLUMNS', 'INITIALLY_SELECT_COLUMNS', 'OPERATORS_AND_LABELS_BY_FILTER_TYPE', 'AVAILABLE_WORK_PACKAGE_FILTERS','DEFAULT_SORT_CRITERIA', 'DEFAULT_QUERY', 'PAGINATION_OPTIONS',
            function($scope, WorkPackagesTableHelper, Query, Sortation, WorkPackageService, AVAILABLE_COLUMNS, INITIALLY_SELECT_COLUMNS, OPERATORS_AND_LABELS_BY_FILTER_TYPE, AVAILABLE_WORK_PACKAGE_FILTERS, DEFAULT_SORT_CRITERIA, DEFAULT_QUERY, PAGINATION_OPTIONS) {

  function initialSetup() {
    $scope.projectIdentifier = gon.project_identifier;
    $scope.operatorsAndLabelsByFilterType = OPERATORS_AND_LABELS_BY_FILTER_TYPE;
    $scope.loading = false;
    $scope.disableFilters = false;
  }

  function setupQuery() {
    // TODO: put the available filters onto the query?
    $scope.query = new Query(DEFAULT_QUERY, { available_work_package_filters: AVAILABLE_WORK_PACKAGE_FILTERS});

    sortation = new Sortation(DEFAULT_SORT_CRITERIA);
    $scope.query.setSortation(sortation);
    $scope.currentSortation = DEFAULT_SORT_CRITERIA;
    // $scope.available_work_package_filters = AVAILABLE_WORK_PACKAGE_FILTERS;

    // Columns
    $scope.columns = INITIALLY_SELECT_COLUMNS;
    $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(AVAILABLE_COLUMNS, $scope.columns);

    angular.extend($scope.query, {
      selectedColumns: $scope.columns
    });
  };

  function setupPagination(json) {
    $scope.paginationOptions = {
      page: json.page,
      perPage: json.per_page
    };
    $scope.perPageOptions = json.per_page_options;
  }

  $scope.submitQueryForm = function(){
    jQuery("#selected_columns option").attr('selected',true);
    jQuery('#query_form').submit();
    return false;
  };

  $scope.setupWorkPackagesTable = function(json) {
    $scope.workPackageCountByGroup = json.work_package_count_by_group;
    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.query.group_by);
    $scope.totalSums = json.sums;
    $scope.groupSums = json.group_sums;
    $scope.totalEntries = json.total_entries;

    setupPagination(json);
  };

  $scope.updateResults = function() {
    $scope.withLoading(WorkPackageService.getWorkPackages, [$scope.projectIdentifier, $scope.query, $scope.paginationOptions])
      .then($scope.setupWorkPackagesTable);
  };

  function serviceErrorHandler(data) {
    // TODO RS: This is where we'd want to put an error message on the dom
    $scope.loading = false;
  };

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

  function initialLoad(){
    // TODO RS: Around about now we need to get the project from the api so that we know about its
    // custom fields so that we can use them as filters.
    setupPagination(PAGINATION_OPTIONS);
    $scope.updateResults();
  };

  initialSetup();
  setupQuery();
  initialLoad();

  // Initialize work package table
  // $scope.setupWorkPackagesTable(gon);
}]);
