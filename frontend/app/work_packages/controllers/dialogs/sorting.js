//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

module.exports = function(sortingModal, $scope, $filter, QueryService, I18n) {
  this.name    = 'Sorting';
  this.closeMe = sortingModal.deactivate;

  $scope.availableColumnsData = [];
  $scope.sortElements = [];
  $scope.initSortation = function(){
    var currentSortation = QueryService.getSortation();

    $scope.sortElements = currentSortation.sortElements.map(function(element){
      return [
        $scope.availableColumnsData.filter(function(column) { return column.id == element.field; })[0],
        $scope.availableDirectionsData.filter(function(direction) { return direction.id == element.direction; })[0]
      ];
    });

    fillUpSortElements();
  };

  function fillUpSortElements() {
    while($scope.sortElements.length < 3) {
      $scope.sortElements.push([{}, $scope.availableDirectionsData[1]]);
    }
  }

  // reduction of column options to columns that haven't been selected

  function getIdsOfSelectedSortElements() {
    return $scope.sortElements
      .map(function(sortElement) {
        if (sortElement.length) return sortElement[0].id;
      })
      .filter(function(element) { return element; });
  }
  function getRemainingAvailableColumnsData() {
    return $scope.availableColumnsData.filter(function(availableColumn) {
      return getIdsOfSelectedSortElements().indexOf(availableColumn.id) === -1;
    });
  }

  $scope.getRemainingAvailableColumnsData = getRemainingAvailableColumnsData;
  // updates

  $scope.updateSortation = function(){
    var sortElements = $scope.sortElements
      .filter(function(element){
        return element.length == 2;
      })
      .map(function(element){
        return { field: element[0].id, direction: element[1].id };
      });
    QueryService.updateSortElements(sortElements);

    sortingModal.deactivate();
  };

  // setup

  $scope.availableDirectionsData = [{ id: 'desc', label: I18n.t('js.label_descending')}, { id: 'asc', label: I18n.t('js.label_ascending')}];

  var blankOption = { id: null, label: ' ', other: null };

  $scope.promise = QueryService.loadAvailableColumns()
    .then(function(available_columns){

      $scope.availableColumnsData = available_columns
        .filter(function(column){
          return !!column.sortable;
        })
        .map(function(column){
          return { id: column.name, label: column.title, other: column.title };
        });
      $scope.availableColumnsData.unshift(blankOption);

      $scope.initSortation();
    });
};
