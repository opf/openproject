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


import { WorkPackageTableTimelineService } from './../wp-fast-table/state/wp-table-timeline.service';
import {scopedObservable} from "../../helpers/angular-rx-utils";
import {KeepTabService} from "../wp-panels/keep-tab/keep-tab.service";
import {WorkPackageTimelineTableController} from './timeline/wp-timeline-container.directive';
import * as MouseTrap from "mousetrap";
import {States} from './../states.service';
import {WorkPackageCacheService} from '../work-packages/work-package-cache.service';
import {WorkPackageDisplayFieldService} from './../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageCollectionResource} from '../api/api-v3/hal-resources/wp-collection-resource.service';
import {WorkPackageTableColumnsService} from '../wp-fast-table/state/wp-table-columns.service';
import {WorkPackageTableSortByService} from '../wp-fast-table/state/wp-table-sort-by.service';
import {WorkPackageTableGroupByService} from '../wp-fast-table/state/wp-table-group-by.service';
import {WorkPackageTableFiltersService} from '../wp-fast-table/state/wp-table-filters.service';
import {WorkPackageTableSumService} from '../wp-fast-table/state/wp-table-sum.service';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageTable} from './../wp-fast-table/wp-fast-table';
import {ContextMenuService} from '../context-menus/context-menu.service';
import {debugLog} from '../../helpers/debug_output';
import {Observable} from 'rxjs/Observable';

angular
  .module('openproject.workPackages.directives')
  .directive('wpTable', wpTable);

function wpTable(
  keepTab:KeepTabService,
  I18n:op.I18n,
  $window:ng.IWindowService,
  PathHelper:any,
  columnsModal:any,
  states:States,
  contextMenu:ContextMenuService
){
  return {
    restrict: 'E',
    replace: true,
    require: '^wpTimelineContainer',
    templateUrl: '/components/wp-table/wp-table.directive.html',
    scope: {
      projectIdentifier: '='
    },

    controller: WorkPackagesTableController,

    link: function(scope:any,
                   element:ng.IAugmentedJQuery,
                   attributes:ng.IAttributes,
                   wpTimelineContainer:WorkPackageTimelineTableController) {
      var activeSelectionBorderIndex;
      scope.wpTimelineContainer = wpTimelineContainer;

      var t0 = performance.now();

      const timeline = element.find('.wp-table-timeline--body');
      const tbody = element.find('.work-package--results-tbody');
      scope.tbody = tbody;
      scope.table = new WorkPackageTable(element[0], tbody[0], timeline[0], wpTimelineContainer);


      var t1 = performance.now();
      debugLog("Render took " + (t1 - t0) + " milliseconds.");

      scope.workPackagePath = PathHelper.workPackagePath;

      var topMenuHeight = angular.element('#top-menu').prop('offsetHeight') || 0;
      scope.adaptVerticalPosition = function(event:JQueryEventObject) {
        event.pageY -= topMenuHeight;
      };

      scope.sumsLoaded = function() {
        return scope.displaySums &&
          scope.resource.sumsSchema &&
          scope.resource.sumsSchema.$loaded &&
          scope.resource.totalSums;
      };

      // Set and keep the current details tab state remembered
      // for the open-in-details button in each WP row.
      scope.desiredSplitViewState = keepTab.currentDetailsState;
      scopedObservable(scope, keepTab.observable).subscribe((tabs:any) => {
        scope.desiredSplitViewState = tabs.details;
      });


     /** Open the settings modal */
     scope.openColumnsModal = function() {
       contextMenu.close();
       columnsModal.activate();
     };
    }
  };
}

class WorkPackagesTableController {
  constructor(private $scope:any,
              $rootScope:ng.IRootScopeService,
              states:States,
              I18n:op.I18n,
              wpTableGroupBy:WorkPackageTableGroupByService,
              wpTableSum:WorkPackageTableSumService,
              wpTableTimeline:WorkPackageTableTimelineService,
              wpTableColumns:WorkPackageTableColumnsService,
             ) {
    // Clear any old table subscribers
    states.table.stopAllSubscriptions.next();

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
      addColumns: I18n.t('js.label_add_columns'),
      tableSummary: I18n.t('js.work_packages.table.summary'),
      tableSummaryHints: [
        I18n.t('js.work_packages.table.text_inline_edit'),
        I18n.t('js.work_packages.table.text_select_hint'),
        I18n.t('js.work_packages.table.text_sort_hint')
      ].join(' ')
    };

    $scope.cancelInlineWorkPackage = function (index:number, row:any) {
      $rootScope.$emit('inlineWorkPackageCreateCancelled', index, row);
    };

    Observable.combineLatest(
      scopedObservable($scope, states.table.query.values$()),
      scopedObservable($scope, states.table.results.values$()),
      wpTableSum.observeOnScope($scope),
      wpTableGroupBy.observeOnScope($scope),
      wpTableColumns.observeOnScope($scope),
      wpTableTimeline.observeOnScope($scope)
    ).subscribe(([query, results, sum, groupBy, columns, timelines]) => {

      $scope.query = query;
      $scope.resource = results;
      $scope.rowcount = results.count;

      $scope.displaySums = sum.current;
      $scope.groupBy = groupBy.current;
      $scope.columns = columns.current;
      // Total columns = all available columns + id + checkbox
      $scope.numTableColumns = $scope.columns.length + 2;

      $scope.timelineVisible = timelines.current;

      if (sum.current) {
        if (!this.sumsSchemaFetched()) { this.fetchSumsSchema(); }
      }
    });
  }

  private sumsSchemaFetched() {
    return this.$scope.resource.sumsSchema && this.$scope.resource.sumsSchema.$loaded;
  }

  private fetchSumsSchema() {
    if (this.$scope.resource.sumsSchema && !this.$scope.resource.sumsSchema.$loaded) {
      this.$scope.resource.sumsSchema.$load();
    }
  }
}
