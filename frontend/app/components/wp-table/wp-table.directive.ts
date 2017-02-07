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
import {ContextMenuService} from '../context-menus/context-menu.service';
import {debug_log} from '../../helpers/debug_output';

angular
  .module('openproject.workPackages.directives')
  .directive('wpTable', wpTable);

function wpTable(
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
  contextMenu:ContextMenuService,
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
      rowcount: '=',
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

      var t0 = performance.now();
      scope.tbody = element.find('.work-package--results-tbody');
      scope.table = new WorkPackageTable(scope.tbody[0]);

      var t1 = performance.now();
      debug_log("Render took " + (t1 - t0) + " milliseconds.")

      // Total columns = all available columns + id + checkbox
      scope.numTableColumns = scope.columns.length + 2;

      scope.workPackagePath = PathHelper.workPackagePath;

      var topMenuHeight = angular.element('#top-menu').prop('offsetHeight') || 0;
      scope.adaptVerticalPosition = function(event) {
        event.pageY -= topMenuHeight;
      };

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
      });

      scope.$watch('displaySums', function(sumsToBeDisplayed) {
        if (sumsToBeDisplayed) {
          if (!totalSumsFetched()) { fetchTotalSums(); }
          if (!sumsSchemaFetched()) { fetchSumsSchema(); }
        }
      });

      // Set and keep the current details tab state remembered
      // for the open-in-details button in each WP row.
      scope.desiredSplitViewState = keepTab.currentDetailsState;
      scopedObservable(scope, keepTab.observable).subscribe((tabs:any) => {
        scope.desiredSplitViewState = tabs.details;
      });

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

     /** Open the settings modal */
     scope.openColumnsModal = function() {
       contextMenu.close();
       columnsModal.activate();
     };
    }
  };
}

function WorkPackagesTableController($scope, $rootScope, I18n) {
  $scope.locale = I18n.locale;

  $scope.text = {
    cancel: I18n.t('js.button_cancel'),
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
