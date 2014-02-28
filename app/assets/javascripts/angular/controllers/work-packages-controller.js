angular.module('openproject.workPackages.controllers')

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', 'Query', 'Sortation', 'WorkPackageService', function($scope, WorkPackagesTableHelper, Query, Sortation, WorkPackageService) {

  $scope.$watch('groupBy', function() {
    var groupByColumnIndex = $scope.columns.map(function(column){
      return column.name;
    }).indexOf($scope.groupBy);

    $scope.groupByColumn = $scope.columns[groupByColumnIndex];
    $scope.query.group_by = $scope.groupBy; // keep the query in sync
  });

  $scope.$watch('perPage', function() {
    $scope.query.per_page = $scope.perPage;
  });

  $scope.$watch('page', function() {
    $scope.query.page = $scope.page;
  });

  function initialSetup() {
    $scope.projectIdentifier = gon.project_identifier;
    $scope.operatorsAndLabelsByFilterType = gon.operators_and_labels_by_filter_type;
    $scope.loading = false;
  }

  function setupQuery() {
    var options = {
      page: gon.page,
      per_page: gon.per_page
    };

    $scope.query = new Query(gon.query, options);

    sortation = new Sortation(gon.sort_criteria);
    $scope.query.setSortation(sortation);

    // Columns
    $scope.columns = gon.columns;
    $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(gon.available_columns, $scope.columns);

    $scope.groupBy = $scope.query.group_by;

    angular.extend($scope.query, {
      selectedColumns: $scope.columns
    });
  }

  $scope.setupWorkPackagesTable = function(json) {
    $scope.workPackageCountByGroup = json.work_package_count_by_group;
    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.groupBy);
    $scope.totalSums = json.sums;
    $scope.groupSums = json.group_sums;
    $scope.page = json.page;
    $scope.perPage = json.per_page;
    $scope.totalEntries = json.total_entries;
  };

  // Initially setup scope via gon
  initialSetup();
  setupQuery(gon);
  $scope.setupWorkPackagesTable(gon);

  $scope.updateResults = function() {
    $scope.withLoading(WorkPackageService.getWorkPackages, [$scope.projectIdentifier, $scope.query])
      .then($scope.setupWorkPackagesTable);
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
    params.push(serviceErrorHandler);
    return callback.apply(this, params)
      .then(function(data){
        finishedLoading();
        return data;
      }, serviceErrorHandler);
  };

  function startedLoading() {
    $scope.loading = true;
  }

  function finishedLoading() {
    $scope.loading = false;
  }

  function serviceErrorHandler(data) {
    // TODO RS: This is where we'd want to put an error message on the dom
    $scope.loading = false;
  }
}]);
