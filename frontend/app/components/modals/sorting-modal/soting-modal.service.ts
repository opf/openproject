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

import {wpControllersModule} from '../../../angular-modules';

function SortingModalController(sortingModal,
                                $scope,
                                $filter,
                                QueryService,
                                I18n) {
  this.name = 'Sorting';
  this.closeMe = sortingModal.deactivate;

  var blankOption = {id: 'null', label: I18n.t('js.placeholders.default'), other: 'null'};

  $scope.availableColumnsData = [];
  $scope.sortElements = [];
  $scope.initSortation = () => {
    var currentSortation = QueryService.getSortation();

    $scope.sortElements = currentSortation.sortElements.map(element => {
      const columns = $scope.availableColumnsData
        .filter(column => column.id === element.field);

      const directions = $scope.availableDirectionsData
        .filter(direction => direction.id === element.direction);

      return [columns, directions].map(item => item[0]);
    });

    fillUpSortElements();
  };

  function fillUpSortElements() {
    while ($scope.sortElements.length < 3) {
      $scope.sortElements.push([blankOption, $scope.availableDirectionsData[1]]);
    }
  }

  // reduction of column options to columns that haven't been selected
  function getIdsOfSelectedSortElements() {
    return $scope.sortElements
      .map(sortElement => {
        if (sortElement.length && sortElement[0]) {
          return sortElement[0].id;
        }
      })
      .filter(element => !!element);
  }

  function getRemainingAvailableColumnsData(selectedElement) {
    var idsOfSelectedSortElements = getIdsOfSelectedSortElements();

    var availableColumns = $scope.availableColumnsData.filter(availableColumn => {
      return idsOfSelectedSortElements.indexOf(availableColumn.id) === -1;
    });

    if (selectedElement.id !== blankOption.id) {
      availableColumns.unshift(selectedElement);
    }

    availableColumns = $filter('orderBy')(availableColumns, 'label');
    availableColumns.unshift(blankOption);

    return availableColumns;
  }

  $scope.getRemainingAvailableColumnsData = getRemainingAvailableColumnsData;

  $scope.updateSortation = () => {
    var sortElements = $scope.sortElements
      .filter(element => element[0].id !== blankOption.id)
      .map(element => ({field: element[0].id, direction: element[1].id}));

    QueryService.updateSortElements(sortElements);
    sortingModal.deactivate();
  };

  $scope.availableDirectionsData = [
    {id: 'desc', label: I18n.t('js.label_descending')},
    {id: 'asc', label: I18n.t('js.label_ascending')}
  ];

  $scope.promise = QueryService.loadAvailableColumns()
    .then(availableColumns => {
      $scope.availableColumnsData = availableColumns
        .filter(column => !!column.sortable)
        .map(column => ({id: column.name, label: column.title, other: column.title}));

      $scope.initSortation();
    });
}

function sortingModalService(btfModal) {
  return btfModal({
    controller: SortingModalController,
    controllerAs: '$ctrl',
    afterFocusOn: '#work-packages-settings-button',
    template: `
      <div class="ng-modal-window">
        <div class="ng-modal-inner modal-content">
          <div class="modal-header">
            <a><i class="icon-close" ng-click="$ctrl.closeMe()" title="{{ ::I18n.t('js.close_popup_title') }}"></i></a></div>

          <h3>{{ ::I18n.t('js.label_sorting') }}</h3>

          <form name="modalSortingForm">
            <div id="modal-sorting" class="modal-content-container" cg-busy="{promise: promise, message: I18n.t('js.label_please_wait')}">
              <div class="form--row" ng-repeat="element in sortElements">
                <div class="form--field -full-width">
                  <label
                     for="modal-sorting-attribute-{{$index}}"
                     class="form--label hidden-for-sighted">
                    {{ I18n.t('js.filter.sorting.criteria.' + { 1: 'one', 2: 'two', 3: 'three'}[$index + 1]) }}
                  </label>
                  <div class="form--field-container">
                    <div class="form--select-container">
                      <select
                         id="modal-sorting-attribute-{{$index}}"
                         ng-model="element[0]"
                         focus="!$index"
                         class="form--select"
                         ng-options="column.label for column in getRemainingAvailableColumnsData(element[0]) track by column.id">
                      </select>
                    </div>
                  </div>
                </div>
                <div class="form--field -full-width">
                  <div class="form--field-container">
                    <label class="option-label">
                      <input type="radio"
                             ng-model="element[1]"
                             ng-required="element[0].id"
                             ng-disabled="!element[0].id"
                             ng-value="availableDirectionsData[1]"
                             name="modal-sorting-attribute-{{$index}}--sort-direction">
                      {{availableDirectionsData[1].label}}
                    </label>
                    <label class="option-label">
                      <input type="radio"
                             ng-model="element[1]"
                             ng-required="element[0].id"
                             ng-disabled="!element[0].id"
                             ng-value="availableDirectionsData[0]"
                             name="modal-sorting-attribute-{{$index}}--sort-direction">
                      {{availableDirectionsData[0].label}}
                    </label>
                  </div>
                </div>
              </div>
            </div>
            <button class="button -highlight"
                    ng-disabled="modalSortingForm.$invalid"
                    ng-click="updateSortation()">
              {{ ::I18n.t('js.modals.button_apply') }}
            </button>
            <button class="button" ng-click="$ctrl.closeMe()">
              {{ ::I18n.t('js.modals.button_cancel') }}
            </button>
          </form>
        </div>
      </div>`
  });
}

wpControllersModule.factory('sortingModal', sortingModalService);
