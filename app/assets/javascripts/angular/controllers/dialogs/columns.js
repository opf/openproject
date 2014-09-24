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
    templateUrl:  '/templates/work_packages/modals/columns.html',
    afterFocusOn: '#work-packages-settings-button'
  });
}])

.controller('ColumnsModalController', ['$scope',
  '$filter',
  'columnsModal',
  'QueryService',
  'WorkPackageService',
  'WorkPackagesTableService',
  '$rootScope',
  function($scope, $filter, columnsModal, QueryService, WorkPackageService, WorkPackagesTableService, $rootScope) {

  this.name    = 'Columns';
  this.closeMe = columnsModal.deactivate;

  $scope.getObjectsData = function(term, result) {
    // Note: This relies on the columns having been cached in the service so they can be instantly available.
    result($filter('filter')($scope.availableColumnsData.filter(function(column) {
        //Note: very special case; if such columns shall multiple, we better add a field
        // to the query model hash of available columns
        return column.id != "id";
      }), {label: term}));
  };

  // Data conversion for select2
  function convertColumnsForSelect2(columns) {
    return columns.map(function(column){
      return { id: column.name, label: column.title, other: column.title };
    });
  }
  function getColumnIdentifiersFromSelection(selectedColumnsData) {
    return selectedColumnsData.map(function(column) { return column.id; });
  }

  // Selected Columns
  var selectedColumns = QueryService.getSelectedColumns();
  var previouslySelectedColumnNames = selectedColumns
    .map(function(column){ return column.name; });

  function getNewlyAddedColumns() {
    return selectedColumns.select(function(column){
      return previouslySelectedColumnNames.indexOf(column.name) < 0;
    });
  }

  $scope.selectedColumnsData = convertColumnsForSelect2(selectedColumns);

  // Available selectable Columns
  QueryService.loadAvailableColumns()
    .then(function(availableColumns){
      $scope.availableColumns = availableColumns;
      $scope.availableColumnsData = convertColumnsForSelect2(availableColumns);
    });


  $scope.updateSelectedColumns = function(){
    // Note: Can't directly manipulate selected columns because select2 returns a new array when you change the values:(
    QueryService.setSelectedColumns(getColumnIdentifiersFromSelection($scope.selectedColumnsData));

    // Augment work packages with new columns data
    var addedColumns        = getNewlyAddedColumns(),
        currentWorkPackages = WorkPackagesTableService.getRowsData(),
        groupBy             = WorkPackagesTableService.getGroupBy();

    if(groupBy.length === 0) groupBy = undefined; // don't pass an empty string as groupBy

    if(addedColumns.length) {
      $rootScope.refreshWorkPackages = WorkPackageService.augmentWorkPackagesWithColumnsData(currentWorkPackages, addedColumns, groupBy);
    }

    columnsModal.deactivate();
  };
}]);
