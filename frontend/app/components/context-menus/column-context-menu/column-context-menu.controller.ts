// -- copyright
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
// ++

import {WorkPackageTableHierarchiesService} from './../../wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackageTableColumnsService} from '../../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableSortByService} from '../../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableGroupByService} from '../../wp-fast-table/state/wp-table-group-by.service';

angular
  .module('openproject.workPackages')
  .controller('ColumnContextMenuController', ColumnContextMenuController);

function ColumnContextMenuController($scope:any,
                                     columnContextMenu:any,
                                     wpTableColumns:WorkPackageTableColumnsService,
                                     wpTableSortBy:WorkPackageTableSortByService,
                                     wpTableGroupBy:WorkPackageTableGroupByService,
                                     wpTableHierarchies:WorkPackageTableHierarchiesService,
                                     I18n:op.I18n,
                                     columnsModal:any) {

  $scope.I18n = I18n;
  $scope.text = {
    sortAscending: I18n.t('js.work_packages.query.sort_ascending'),
    sortDescending: I18n.t('js.work_packages.query.sort_descending'),
    groupBy: I18n.t('js.work_packages.query.group'),
    moveLeft: I18n.t('js.work_packages.query.move_column_left'),
    moveRight: I18n.t('js.work_packages.query.move_column_right'),
    hide: I18n.t('js.work_packages.query.hide_column'),
    insert: I18n.t('js.work_packages.query.insert_columns')
  };

  $scope.$watch('column', function () {
    // fall back to 'id' column as the default
    $scope.column = $scope.column || {name: 'id', sortable: true};
    $scope.isGroupable = wpTableGroupBy.isGroupable($scope.column) && !wpTableGroupBy.isCurrentlyGroupedBy($scope.column);
    $scope.isSortable = wpTableSortBy.isSortable($scope.column);
  });

  // context menu actions

  $scope.groupBy = function () {
    wpTableGroupBy.setBy($scope.column);
  };

  $scope.sortAscending = function () {
    wpTableSortBy.addAscending($scope.column);
  };

  $scope.sortDescending = function () {
    wpTableSortBy.addDescending($scope.column);
  };

  $scope.moveLeft = function () {
    wpTableColumns.shift($scope.column, -1);
  };

  $scope.moveRight = function () {
    wpTableColumns.shift($scope.column, 1);
  };

  $scope.hideColumn = function () {
    columnContextMenu.close();
    let previousColumn = wpTableColumns.previous($scope.column);
    wpTableColumns.removeColumn($scope.column);

    window.setTimeout(function () {
      if (previousColumn) {
        jQuery('#' + previousColumn.id).focus();
      } else {
        jQuery('th.checkbox a').focus();
      }
    }, 100);
  };

  $scope.insertColumns = function () {
    columnsModal.activate();
  };

  $scope.canMoveLeft = function () {
    return !wpTableColumns.isFirst($scope.column);
  };

  $scope.canMoveRight = function () {
    return !wpTableColumns.isLast($scope.column);
  };

  $scope.canBeHidden = function () {
    return true;
  };

  $scope.focusFeature = function (feature:string) {
    var focus;
    var mergeOrReturn = function (currentState:any, state:any) {
      return ((currentState === undefined) ? state : currentState && !state);
    };

    switch (feature) {
      case 'insert':
        focus = mergeOrReturn(focus, true);
        break;
      case 'hide':
        focus = mergeOrReturn(focus, $scope.canBeHidden());
        break;
      case 'moveRight':
        focus = mergeOrReturn(focus, $scope.canMoveRight());
        break;
      case 'moveLeft':
        focus = mergeOrReturn(focus, $scope.canMoveLeft());
        break;
      case 'group':
        focus = mergeOrReturn(focus, !!$scope.isGroupable);
        break;
      default:
        focus = mergeOrReturn(focus, $scope.canSort());
        break;
    }

    return focus;
  };
}
