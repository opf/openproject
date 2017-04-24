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

import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {QueryResource} from "../../api/api-v3/hal-resources/query-resource.service";
import {LoadingIndicatorService} from "../../common/loading-indicator/loading-indicator.service";
import {States} from "../../states.service";
import {WorkPackageTableColumnsService} from "../../wp-fast-table/state/wp-table-columns.service";
import {WorkPackageTableFiltersService} from "../../wp-fast-table/state/wp-table-filters.service";
import {WorkPackageTableGroupByService} from "../../wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageTablePaginationService} from "../../wp-fast-table/state/wp-table-pagination.service";
import {WorkPackageTableSortByService} from "../../wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableSumService} from "../../wp-fast-table/state/wp-table-sum.service";
import {WorkPackageTablePagination} from "../../wp-fast-table/wp-table-pagination";
import {WorkPackageTableHierarchiesService} from './../../wp-fast-table/state/wp-table-hierarchy.service';
import {WorkPackagesListChecksumService} from "../../wp-list/wp-list-checksum.service";
import {WorkPackagesListService} from "../../wp-list/wp-list.service";
import {WorkPackageTableTimelineService} from "../../wp-fast-table/state/wp-table-timeline.service";

function WorkPackagesListController($scope:any,
                                    $rootScope:ng.IRootScopeService,
                                    $state:ng.ui.IStateService,
                                    $q:ng.IQService,
                                    AuthorisationService:any,
                                    states:States,
                                    wpTableColumns:WorkPackageTableColumnsService,
                                    wpTableSortBy:WorkPackageTableSortByService,
                                    wpTableGroupBy:WorkPackageTableGroupByService,
                                    wpTableFilters:WorkPackageTableFiltersService,
                                    wpTableSum:WorkPackageTableSumService,
                                    wpTableTimeline:WorkPackageTableTimelineService,
                                    wpTableHierarchies:WorkPackageTableHierarchiesService,
                                    wpTablePagination:WorkPackageTablePaginationService,
                                    wpListService:WorkPackagesListService,
                                    wpListChecksumService:WorkPackagesListChecksumService,
                                    loadingIndicator:LoadingIndicatorService,
                                    I18n:op.I18n) {

  $scope.projectIdentifier = $state.params['projectPath'] || null;
  $scope.I18n = I18n;
  $scope.text = {
    'jump_to_pagination': I18n.t('js.work_packages.jump_marks.pagination'),
    'text_jump_to_pagination': I18n.t('js.work_packages.jump_marks.label_pagination')
  };

  // Setup
  function initialSetup() {
    setupObservers();

    if (wpListChecksumService.isUninitialized()) {
      loadQuery();
    }
  }

  function setupObservers() {

    scopedObservable($scope, states.table.query.values$())
      .withLatestFrom(
        wpTablePagination.observeOnScope($scope)
      ).subscribe(([query, pagination]) => {
      $scope.tableInformationLoaded = true;

      updateTitle(query);

      wpListChecksumService.updateIfDifferent(query, pagination as WorkPackageTablePagination);
    });

    wpTablePagination.observeOnScope($scope)
      .withLatestFrom(scopedObservable($scope, states.table.query.values$()))
      .subscribe(([pagination, query]) => {
      if (wpListChecksumService.isQueryOutdated(query, pagination as WorkPackageTablePagination)) {
        wpListChecksumService.update(query, pagination as WorkPackageTablePagination);

        updateResultsVisibly();
      }
    });

    wpTableFilters.observeOnScope($scope).subscribe(filters => {
      updateAndExecuteIfAltered(filters.current, 'filters', true);
    });

    wpTableGroupBy.observeOnScope($scope).subscribe(groupBy => {
      updateAndExecuteIfAltered(groupBy.current, 'groupBy', true);
    });

    wpTableSortBy.observeOnScope($scope).subscribe(sortBy => {
      updateAndExecuteIfAltered(sortBy.current, 'sortBy', true);
    });

    wpTableSum.observeOnScope($scope).subscribe(sums => {
      updateAndExecuteIfAltered(sums.current, 'sums', true);
    });

    wpTableTimeline.observeOnScope($scope).subscribe(timeline => {
      updateAndExecuteIfAltered(timeline.current, "timelineVisible");
    });

    wpTableHierarchies.observeOnScope($scope).subscribe(hierarchies => {
      updateAndExecuteIfAltered(hierarchies.current, 'showHierarchies');
    });

    wpTableColumns.observeOnScope($scope).subscribe(columns => {
      updateAndExecuteIfAltered(columns.current, "columns");
    });
  }

  function updateAndExecuteIfAltered(updateData:any, name:string, triggerUpdate:boolean = false) {
    if (isAnyDependentStateClear()) {
      return;
    }

    let query = states.table.query.value;

    if (!query || _.isEqual(query[name], updateData)) {
      return;
    }

    let pagination = wpTablePagination.current;

    query[name] = _.cloneDeep(updateData);

    states.table.query.putValue(query);

    if (triggerUpdate) {
      updateResultsVisibly(true);
    }
  }

  function loadQuery() {
    wpListChecksumService.clear();
    loadingIndicator.table.promise = wpListService.fromQueryParams($state.params, $scope.projectIdentifier);
  }

  $scope.setAnchorToNextElement = function () {
    // Skip to next when visible, otherwise skip to previous
    const selectors = '#pagination--next-link, #pagination--prev-link, #pagination-empty-text';
    const visibleLink = jQuery(selectors)
                          .not(':hidden')
                          .first();

   if (visibleLink.length) {
     visibleLink.focus();
   }
  }

  function updateResults() {
    return wpListService.reloadCurrentResultsList()
  }

  function updateToFirstResultsPage() {
    return wpListService.loadCurrentResultsListFirstPage();
  }

  function updateResultsVisibly(firstPage:boolean = false) {
    if (firstPage) {
      loadingIndicator.table.promise = updateToFirstResultsPage();
    } else {
      loadingIndicator.table.promise = updateResults();
    }
  }

  $scope.allowed = function(model:string, permission:string) {
    return AuthorisationService.can(model, permission);
  };

  initialSetup();

  function updateTitle(query:QueryResource) {
    if (query.id) {
      $scope.selectedTitle = query.name;
    } else {
      $scope.selectedTitle = I18n.t('js.label_work_package_plural');
    }
  }

  $scope.$watchCollection(
    () => {
      return {
        query_id: $state.params['query_id'],
        query_props: $state.params['query_props']
      };
    },
    (params:any) => {
      let newChecksum = params.query_props;
      let newId = params.query_id && parseInt(params.query_id);

      wpListChecksumService.executeIfOutdated(newId,
                                              newChecksum,
                                              loadQuery);
    });

  // The combineLatest retains the last value of each observable regardless of
  // whether it has become null|undefined in the meantime.
  // As we alter the query's property from it's dependent states, we have to ensure
  // that we do not set them if he dependent state does depend on another query with
  // the value only being available because it is still retained.
  function isAnyDependentStateClear() {
    return !states.table.pagination.value ||
      !states.table.filters.value ||
      !states.table.columns.value ||
      !states.table.sortBy.value ||
      !states.table.groupBy.value ||
      !states.table.timelineVisible.value ||
      !states.table.hierarchies.value ||
      !states.table.sum.value;
  }

  $rootScope.$on('workPackagesRefreshRequired', function () {
    updateResultsVisibly();
  });

  $rootScope.$on('workPackagesRefreshInBackground', function () {
    updateResults();
  });
}

angular
  .module('openproject.workPackages.controllers')
  .controller('WorkPackagesListController', WorkPackagesListController);
