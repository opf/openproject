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

.controller('WorkPackagesController', ['$scope', '$window', '$location', 'WorkPackagesTableHelper', 'WorkPackageService', 'QueryService', 'PaginationService', 'WorkPackageLoadingHelper', 'INITIALLY_SELECTED_COLUMNS', 'OPERATORS_AND_LABELS_BY_FILTER_TYPE',
            function($scope, $window, $location, WorkPackagesTableHelper, WorkPackageService, QueryService, PaginationService, WorkPackageLoadingHelper, INITIALLY_SELECTED_COLUMNS, OPERATORS_AND_LABELS_BY_FILTER_TYPE) {


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

    if($location.search()['c[]']){
      var getMethod = WorkPackageService.getWorkPackagesFromUrlQueryParams;
      var params = [$scope.projectIdentifier, $location];
    } else {
      var getMethod = WorkPackageService.getWorkPackagesByQueryId;
      var params = [$scope.projectIdentifier, $scope.query_id];
    }

    $scope.withLoading(getMethod, params)
      .then($scope.setupWorkPackagesTable)
      .then(initAvailableColumns);
  }

  function initAvailableColumns() {
    return QueryService.getAvailableColumns($scope.projectIdentifier)
      .then(function(data){
        $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(data.available_columns, $scope.columns);
        return $scope.availableColumns;
      });
  }

  function afterQuerySetupCallback(query) {
    $scope.showFilters = query.filters.length > 0;
    $scope.updateBackUrl();
  }

  $scope.updateBackUrl = function(){
    // Easier than trying to extract it from $location
    var relativeUrl = "/work_packages";
    if ($scope.projectIdentifier){
      relativeUrl = "/projects/" + $scope.projectIdentifier + relativeUrl;
    }

    if($scope.query){
      relativeUrl = relativeUrl + "#?" + $scope.query.serialiseForAngular();
    }

    $scope.backUrl = relativeUrl;
  };

  $scope.submitQueryForm = function(){
    jQuery("#selected_columns option").attr('selected',true);
    jQuery('#query_form').submit();
    return false;
  };

  $scope.setupWorkPackagesTable = function(json) {
    var meta = json.meta;

    if (!$scope.columns) $scope.columns = meta.columns;
    if (!$scope.groupableColumns) $scope.groupableColumns = meta.groupable_columns;
    $scope.query = QueryService.getQuery() || QueryService.initQuery($scope.query_id, meta.query, $scope.columns, afterQuerySetupCallback);

    PaginationService.setPerPageOptions(meta.per_page_options);
    PaginationService.setPerPage(meta.per_page);
    PaginationService.setPage(meta.page);

    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.query.groupBy);

    $scope.workPackageCountByGroup = meta.work_package_count_by_group;
    $scope.totalEntries = meta.total_entries;
    angular.forEach($scope.columns, function(column, i){
      column.total_sum = meta.sums[i];
      if (meta.group_sums) column.group_sums = meta.group_sums[i];
    });
    $scope.updateBackUrl();
  };

  $scope.updateResults = function() {
    $scope.$broadcast('openproject.workPackages.updateResults');

    return $scope.withLoading(WorkPackageService.getWorkPackages, [$scope.projectIdentifier, $scope.query, PaginationService.getPaginationOptions()])
      .then($scope.setupWorkPackagesTable);
  };

  function serviceErrorHandler(data) {
    // TODO RS: This is where we'd want to put an error message on the dom
    $scope.isLoading = false;
  }

  $scope.withLoading = function(callback, params){
    return WorkPackageLoadingHelper.withLoading($scope, callback, params, serviceErrorHandler);
  };

  setUrlParams($window.location);
  initialSetup();
}]);
