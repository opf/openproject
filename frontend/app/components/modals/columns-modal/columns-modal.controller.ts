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
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';

function ColumnsModalController($scope,
                                $timeout,
                                I18n,
                                columnsModal,
                                wpTableColumns:WorkPackageTableColumnsService,
                                QueryService,
                                ConfigurationService) {
  var vm = this;

  vm.name = 'Columns';
  vm.closeMe = columnsModal.deactivate;

  vm.selectedColumns = [];
  vm.oldSelectedColumns = [];
  vm.availableColumns = [];
  vm.unusedColumns = [];

  vm.impaired = ConfigurationService.accessibilityModeEnabled();

  vm.selectedColumnMap = {};

  vm.text = {
    closePopup: I18n.t('js.close_popup_title'),
    columnsLabel: I18n.t('js.label_columns'),
    selectedColumns: I18n.t('js.description_selected_columns'),
    multiSelectLabel: I18n.t('js.work_packages.label_column_multiselect'),
    applyButton: I18n.t('js.modals.button_apply'),
    cancelButton: I18n.t('js.modals.button_cancel')
  };

  var selectedColumns = QueryService.getSelectedColumns();

  // Available selectable Columns
  vm.promise = QueryService.loadAvailableColumns($scope.projectIdentifier)
    .then(availableColumns => {
      vm.availableColumns = availableColumns; // all existing columns
      vm.unusedColumns = QueryService.selectUnusedColumns(availableColumns); // columns not shown

      var availableColumnNames = getColumnNames(availableColumns);
      selectedColumns.forEach(column => {
        if (_.contains(availableColumnNames, column.name)) {
          vm.selectedColumns.push(column);
          vm.selectedColumnMap[column.name] = true;
          vm.oldSelectedColumns.push(column);
        }
      });
    });

  function getColumnNames(arr) {
    return arr.map(column => column.name);
  }

  vm.updateSelectedColumns = () => {
    wpTableColumns.setColumns(vm.selectedColumns.map(c => c.name));

    columnsModal.deactivate();
  };

  /**
   * When a column is removed from the selection it becomes unused and hence available for
   * selection again. When a column is added to the selection it becomes used and is
   * therefore unavailable for selection.
   *
   * This function updates the unused columns according to the currently selected columns.
   *
   * @param selectedColumns Columns currently selected through the multi select box.
   */
  vm.updateUnusedColumns = selectedColumns => {
    var used = getColumnNames(selectedColumns);

    vm.unusedColumns = vm.availableColumns.filter(column => !_.contains(used, column.name));
  };

  vm.setSelectedColumn = column => {
    if (vm.selectedColumnMap[column.name]) {
      vm.selectedColumns.push(column);
    }
    else {
      _.remove(vm.selectedColumns, (c: any) => c.name === column.name);
    }
  };

  //hack to prevent dragging of close icons
  $timeout(() => {
    angular.element('.columns-modal-content .ui-select-match-close').on('dragstart', event => {
      event.preventDefault();
    });
  });

  $scope.$on('uiSelectSort:change', (event, args) => {
    vm.selectedColumns = args.array;
  });
}

wpControllersModule.controller('ColumnsModalController', ColumnsModalController);
