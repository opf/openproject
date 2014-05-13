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

.controller('ColumnsModalController', ['$scope', '$timeout', 'columnsModal', 'QueryService', function($scope, $timeout, columnsModal, QueryService) {
  this.name    = 'Columns';
  this.closeMe = columnsModal.deactivate;

  // Selected Columns
  $scope.selectedColumnsString = QueryService.getSelectedColumns()
    .map(function(column){ return column.name; })
    .join();

  // Available Columns
  QueryService.getAvailableColumns()
    .then(function(data){
      var cols = data.available_columns.map(function(column){
        return { name: column.title, id: column.name };
      });
      $scope.availableColumnsString = JSON.stringify(cols);
    })
    .then(function(){
      $timeout(function(){
        var colsInput = jQuery('#selected_columns_new');
        colsInput.autocomplete({
          multiple: true,
          sortable: true
        });
      });
    });

  // TODO: Method to pass back selected columns to service on closing/saving
  $scope.updateSelectedColumns = function(){
    // Hack alert: autocomplete is change the value of the hidden input and so ng-value isn't keeping track of it so just using jQuery
    var cols = jQuery('#selected_columns_new').val();
  }
}]);
