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

.factory('columnsModal', ['btfModal', function(btfModal) {
  return btfModal({
    controller:   'ColumnsModalController',
    controllerAs: 'modal',
    templateUrl:  '/templates/work_packages/modals/columns.html'
  });
}])

.controller('ColumnsModalController', ['$scope',
  '$timeout',
  'columnsModal',
  'QueryService',
  'WorkPackageService',
  'WorkPackagesTableService',
  'QueriesHelper',
  function($scope, $timeout, columnsModal, QueryService, WorkPackageService, WorkPackagesTableService, QueriesHelper) {

  this.name    = 'Columns';
  this.closeMe = columnsModal.deactivate;

  $scope.getObjectsData = function(term, result) {
    // TODO: This is waiting on QueryService.getAvailableColumns() which means if you click to early then it doesn't
    // display anything and will not even if you wait. We need to disable the input while the available columns are being fetched.
    result($scope.availableColumnsData);
  };

  // Selected Columns
  $scope.selectedColumns = QueryService.getSelectedColumns();
  $scope.selectedColumnsData = $scope.selectedColumns
    .map(function(column){ return { id: column.name, label: column.title }; });
  $scope.previouslySelectedColumnNames = $scope.selectedColumns
    .map(function(column){ return column.name; });

  // Available Columns
  QueryService.getAvailableColumns()
    .then(function(available_columns){
      $scope.availableColumns = available_columns
      $scope.availableColumnsData = available_columns.map(function(column){
        return { id: column.name, label: column.title, other: column.title };
      });
    });

  $scope.updateSelectedColumns = function(){
    // Note: Can't directly manipulate selected columns because select2 returns a new array when you change the values:(
    QueryService.setSelectedColumns($scope.availableColumns, $scope.selectedColumnsData.map(function(column){ return column.id; }));

    // Augment work packages with new columns data
    var addedColumns = $scope.selectedColumns.select(function(column){
      return $scope.previouslySelectedColumnNames.indexOf(column.name) < 0;
    });
    var args = [WorkPackagesTableService.getRowsData(), addedColumns];
    if (WorkPackagesTableService.getGroupBy().length){
      args.push(WorkPackagesTableService.getGroupBy());
    }
    WorkPackageService.augmentWorkPackagesWithColumnsData.apply(this, args);

    columnsModal.deactivate();
  }
}]);
