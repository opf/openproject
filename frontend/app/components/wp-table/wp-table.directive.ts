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

import {scopedObservable} from "../../helpers/angular-rx-utils";
import {KeepTabService} from "../wp-panels/keep-tab/keep-tab.service";
import * as MouseTrap from "mousetrap";
import {States} from './../states.service';
import { WorkPackageCacheService } from '../work-packages/work-package-cache.service';
import {WorkPackageDisplayFieldService} from './../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageTable} from './../wp-fast-table/wp-fast-table';
angular
  .module('openproject.workPackages.directives')
  .directive('wpTable', wpTable);

function wpTable(
  WorkPackagesTableService,
  states:States,
  wpDisplayField:WorkPackageDisplayFieldService,
  wpCacheService:WorkPackageCacheService,
  WorkPackageService,
  keepTab:KeepTabService,
  I18n,
  QueryService,
  $window,
  $rootScope,
  PathHelper,
  columnsModal,
  apiWorkPackages,
  $state
){
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/wp-table/wp-table.directive.html',
    scope: {
      projectIdentifier: '=',
      columns: '=',
      rows: '=',
      query: '=',
      groupBy: '=',
      groupHeaders: '=',
      displaySums: '=',
      isSmaller: '=',
      resource: '=',
      activationCallback: '&'
    },

    controller: WorkPackagesTableController,

    link: function(scope, element) {
      var activeSelectionBorderIndex;

      // Total columns = all available columns + id + action link
      scope.tbody = element.find('.work-package-table tbody');
      scope.table = new WorkPackageTable(scope.tbody[0], wpCacheService, states.workPackages, wpDisplayField, I18n);
      scope.table.initialize(scope.rows, scope.columns);

      // Total columns = all available columns + id + checkbox
      scope.numTableColumns = scope.columns.length + 2;

      scope.workPackagesTableData = WorkPackagesTableService.getWorkPackagesTableData();
      scope.workPackagePath = PathHelper.workPackagePath;

      var topMenuHeight = angular.element('#top-menu').prop('offsetHeight') || 0;
      scope.adaptVerticalPosition = function(event) {
        event.pageY -= topMenuHeight;
      };

      applyGrouping();

      scope.$watchCollection('columns', function() {
        // force Browser rerender
        element.hide().show(0);
        scope.numTableColumns = scope.columns.length + 2;

        angular.element($window).trigger('resize');
      });
      scope.$watchCollection('rows', function() {
        // force Browser rerender
        element.hide().show(0);

        angular.element($window).trigger('resize');
      });

      scope.sumsLoaded = function() {
        return scope.displaySums &&
          scope.resource.sumsSchema &&
          scope.resource.sumsSchema.$loaded &&
          scope.resource.totalSums;
      };

      scope.$watch('resource', function() {
        if (scope.displaySums) {
          fetchSumsSchema();
        }

        applyGrouping();
      });

      scope.$watch('displaySums', function(sumsToBeDisplayed) {
        if (sumsToBeDisplayed) {
          if (!totalSumsFetched()) { fetchTotalSums(); }
          if (!sumsSchemaFetched()) { fetchSumsSchema(); }
        }
      });

      // Bind CTRL+A to select all work packages
      Mousetrap.bind(['command+a', 'ctrl+a'], function(e) {
        scope.$evalAsync(() => {
          WorkPackagesTableService.setCheckedStateForAllRows(scope.rows, true);
        });

        e.preventDefault();
        return false;
      });

      // Bind CTRL+D to deselect all work packages
      Mousetrap.bind(['command+d', 'ctrl+d'], function(e) {
        scope.$evalAsync(() => {
          WorkPackagesTableService.setCheckedStateForAllRows(scope.rows, false);
        });

        e.preventDefault();
        return false;
      });

      // Set and keep the current details tab state remembered
      // for the open-in-details button in each WP row.
      scope.desiredSplitViewState = keepTab.currentDetailsState;
      scopedObservable(scope, keepTab.observable).subscribe((tabs:any) => {
        scope.desiredSplitViewState = tabs.details;
      });

      function applyGrouping() {
        if (scope.groupByColumn != scope.workPackagesTableData.groupByColumn) {
          scope.groupByColumn = scope.workPackagesTableData.groupByColumn;
          scope.grouped = scope.groupByColumn !== undefined;
          scope.groupExpanded = {};

          // Open new groups by default
          Object.keys(scope.groupHeaders).forEach((key) => {
            scope.groupExpanded[key] = true;
          });
        }
      }

      function fetchTotalSums() {
        apiWorkPackages
          // TODO: use the correct page offset and per page options
          .list(1, 1, scope.query)
          .then(function(workPackageCollection) {
            angular.extend(scope.resource, workPackageCollection);
            fetchSumsSchema();
          });
      }

      function totalSumsFetched() {
        return !!scope.resource.totalSums;
      }

      function sumsSchemaFetched() {
        return scope.resource.sumsSchema && scope.resource.sumsSchema.$loaded;
      }

      function fetchSumsSchema() {
        if (scope.resource.sumsSchema && !scope.resource.sumsSchema.$loaded) {
          scope.resource.sumsSchema.$load();
        }
      }

      scope.setCheckedStateForAllRows = function(state) {
        WorkPackagesTableService.setCheckedStateForAllRows(scope.rows, state);
      };

      // Thanks to http://stackoverflow.com/a/880518
      function clearSelection() {
        var selection = (document as any).selection;
        if(selection && selection.empty) {
          selection.empty();
        } else if(window.getSelection) {
          var sel = window.getSelection();
          sel.removeAllRanges();
        }
      }

      function setRowSelectionState(row, selected) {
        activeSelectionBorderIndex = scope.rows.indexOf(row);
        WorkPackagesTableService.setRowSelection(row, selected);
      }

      function openWhenInSplitView(workPackage) {
        if ($state.includes('work-packages.list.details')) {
          $state.go(
            $state.$current.name,
            { workPackageId: workPackage.id }
          );
        }
      }

      function mulipleRowsChecked(){
        var counter = 0;
        for (var i = 0, l = scope.rows.length; i<l; i++) {
          if (scope.rows[i].checked) {
            if (++counter === 2) {
              return true;
            }
          }
        }
        return false;
      }

      scope.selectWorkPackage = function(row, $event) {
        // The current row is the last selected work package
        // not matter what other rows are (de-)selected below.
        // Thus save that row for the details view button
        WorkPackageService.cache().put('preselectedWorkPackageId', row.object.id);

        var currentRowCheckState = row.checked;
        var multipleChecked = mulipleRowsChecked();
        var isLink = angular.element($event.target).is('a');

        if (!($event.ctrlKey || $event.shiftKey)) {
          scope.setCheckedStateForAllRows(false);
        }

        if(isLink) {
          return;
        }

        if ($event.shiftKey) {
          clearSelection();
          activeSelectionBorderIndex = WorkPackagesTableService.selectRowRange(scope.rows, row, activeSelectionBorderIndex);
        } else if($event.ctrlKey || $event.metaKey){
          setRowSelectionState(row, multipleChecked ? true : !currentRowCheckState);
        } else {
          setRowSelectionState(row, multipleChecked ? true : !currentRowCheckState);
        }

        // Avoid bubbling of elements within the details link
        if ($event.target.parentElement.className.indexOf('wp-table--details-link') === -1) {
          openWhenInSplitView(row.object);
        }
      };

      scope.openWorkPackageInFullView = function(row) {
        clearSelection();

        scope.setCheckedStateForAllRows(false);

        setRowSelectionState(row, true);

        scope.activationCallback({ id: row.object.id, force: true });
      };

      /** Expand current columns with erroneous columns */
      scope.handleErroneousColumns = function(workPackage, editFields, errorFieldNames)  {
        if (errorFieldNames.length === 0) { return; }

        var selected = QueryService.getSelectedColumnNames();
        var active = _.find(editFields, (f:any) => f.active);

        errorFieldNames.reverse().map(name => {
          if (selected.indexOf(name) === -1) {
          selected.splice(selected.indexOf(active.fieldName) + 1, 0, name);
        }
      });

        QueryService.setSelectedColumns(selected);
        return _.find(selected, (column) => errorFieldNames.indexOf(column) !== -1);
      };

      /** Save callbacks for work package */
     scope.onWorkPackageSave = function(workPackage, fields) {
       $rootScope.$emit('workPackageSaved', workPackage);
       $rootScope.$emit('workPackagesRefreshInBackground');
     };

     /** Open the settings modal */
     scope.openColumnsModal = function() {
       scope.$emit('hideAllDropdowns');
       scope.$root.$broadcast('openproject.dropdown.closeDropdowns', true);
       columnsModal.activate();
     };
    }
  };
}

function WorkPackagesTableController($scope, $rootScope, I18n) {
  $scope.locale = I18n.locale;

  $scope.text = {
    cancel: I18n.t('js.button_cancel'),
    collapse: I18n.t('js.label_collapse'),
    expand: I18n.t('js.label_expand'),
    sumFor: I18n.t('js.label_sum_for'),
    allWorkPackages: I18n.t('js.label_all_work_packages'),
    noResults: {
      title: I18n.t('js.work_packages.no_results.title'),
      description: I18n.t('js.work_packages.no_results.description')
    },
    faultyQuery: {
      title: I18n.t('js.work_packages.faulty_query.title'),
      description: I18n.t('js.work_packages.faulty_query.description')
    },
    tableSummary: I18n.t('js.work_packages.table.summary'),
    tableSummaryHints: [
      I18n.t('js.work_packages.table.text_inline_edit'),
      I18n.t('js.work_packages.table.text_select_hint'),
      I18n.t('js.work_packages.table.text_sort_hint')
    ].join(' ')
  };

  $scope.$watch('workPackagesTableData.allRowsChecked', function(checked) {
    $scope.text.toggleRows =
        checked ? I18n.t('js.button_uncheck_all') : I18n.t('js.button_check_all');
  });

  $scope.cancelInlineWorkPackage = function (index, row) {
    $rootScope.$emit('inlineWorkPackageCreateCancelled', index, row);
  };

  $scope.getTableColumnName = function(workPackage, name) {
    // poor man's implementation to query for whether this wp is a milestone
    // It would be way cleaner to ask whether this work package has a type
    // that is a milestone but that would require us to make another server request.
    if ((name === 'startDate' && _.isUndefined(this.workPackage.startDate)) ||
        (name === 'dueDate' && _.isUndefined(this.workPackage.dueDate))) {
      return 'date';
    }
    else {
      return name;
    }
  }
}
