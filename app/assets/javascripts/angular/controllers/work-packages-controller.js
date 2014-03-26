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

.controller('WorkPackagesController', ['$scope', 'WorkPackagesTableHelper', 'Query', 'Sortation', 'WorkPackageService', function($scope, WorkPackagesTableHelper, Query, Sortation, WorkPackageService) {

  function initialSetup() {
    $scope.projectIdentifier = gon.project_identifier;
    $scope.operatorsAndLabelsByFilterType = gon.operators_and_labels_by_filter_type;
    $scope.loading = false;
    $scope.disableFilters = false;
  }

  function setupQuery() {
    $scope.query = new Query(gon.query);

    sortation = new Sortation(gon.sort_criteria);
    $scope.query.setSortation(sortation);

    // Columns
    $scope.columns = gon.columns;
    $scope.availableColumns = WorkPackagesTableHelper.getColumnDifference(gon.available_columns, $scope.columns);

    $scope.currentSortation = gon.sort_criteria;

    angular.extend($scope.query, {
      selectedColumns: $scope.columns
    });
  };

  $scope.submitQueryForm = function(){
    jQuery("#selected_columns option").attr('selected',true);
    jQuery('#query_form').submit();
    return false;
  };

  function setupPagination(json) {
    $scope.paginationOptions = {
      page: json.page,
      perPage: json.per_page
    };
    $scope.perPageOptions = json.per_page_options;
  }

  $scope.setupWorkPackagesTable = function(json) {
    $scope.workPackageCountByGroup = json.work_package_count_by_group;
    $scope.rows = WorkPackagesTableHelper.getRows(json.work_packages, $scope.query.group_by);
    $scope.totalSums = json.sums;
    $scope.groupSums = json.group_sums;
    $scope.totalEntries = json.total_entries;

    setupPagination(json);
  };

  // Initially setup scope via gon
  initialSetup();
  setupQuery(gon);
  // Initialize work package table
  $scope.setupWorkPackagesTable(gon);

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
  }

  function finishedLoading() {
    $scope.loading = false;
  }
}]);
