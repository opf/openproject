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

import {Injector, OnDestroy, OnInit} from '@angular/core';
import {StateService, TransitionService} from '@uirouter/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {TableState} from 'core-components/wp-table/table-state/table-state';
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {auditTime, filter, take, withLatestFrom} from 'rxjs/operators';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {States} from "core-components/states.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {WorkPackageTableColumnsService} from "core-components/wp-fast-table/state/wp-table-columns.service";
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {WorkPackageTableSumService} from "core-components/wp-fast-table/state/wp-table-sum.service";
import {WorkPackageTableTimelineService} from "core-components/wp-fast-table/state/wp-table-timeline.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageTablePaginationService} from "core-components/wp-fast-table/state/wp-table-pagination.service";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";
import {WorkPackageQueryStateService} from "core-components/wp-fast-table/state/wp-table-base.service";
import {debugLog} from "core-app/helpers/debug_output";

export class WorkPackagesSetComponent implements OnInit, OnDestroy {

  projectIdentifier = this.$state.params['projectPath'] || null;

  tableInformationLoaded = false;

  private removeTransitionSubscription:Function;

  constructor(readonly injector:Injector,
              readonly states:States,
              readonly tableState:TableState,
              readonly authorisationService:AuthorisationService,
              readonly wpTableRefresh:WorkPackageTableRefreshService,
              readonly wpTableColumns:WorkPackageTableColumnsService,
              readonly wpTableHighlighting:WorkPackageTableHighlightingService,
              readonly wpTableSortBy:WorkPackageTableSortByService,
              readonly wpTableGroupBy:WorkPackageTableGroupByService,
              readonly wpTableFilters:WorkPackageTableFiltersService,
              readonly wpTableSum:WorkPackageTableSumService,
              readonly wpTableTimeline:WorkPackageTableTimelineService,
              readonly wpTableHierarchies:WorkPackageTableHierarchiesService,
              readonly wpTablePagination:WorkPackageTablePaginationService,
              readonly wpListService:WorkPackagesListService,
              readonly wpListChecksumService:WorkPackagesListChecksumService,
              readonly loadingIndicator:LoadingIndicatorService,
              readonly $transitions:TransitionService,
              readonly $state:StateService,
              readonly I18n:I18nService,
              readonly wpStaticQueries:WorkPackageStaticQueriesService) {

  }

  ngOnInit() {
    const loadingRequired = this.wpListChecksumService.isUninitialized();

    // Listen to changes on the query state objects
    this.setupQueryObservers();

    this.initialQueryLoading(loadingRequired);

    // Listen for refresh changes
    this.setupRefreshObserver();

    this.updateQueryOnParamsChanges();
  }

  ngOnDestroy():void {
    if (this.removeTransitionSubscription) {
      this.removeTransitionSubscription();
    }
    this.wpTableRefresh.clear('Table controller scope destroyed.');
  }

  private setupQueryObservers() {
    this.tableState.tableRendering.onQueryUpdated.values$()
      .pipe(
        take(1)
      )
      .subscribe(() => this.tableInformationLoaded = true);

    this.tableState.ready.fireOnStateChange(this.wpTablePagination.state,
      'Query loaded').values$().pipe(
      untilComponentDestroyed(this),
      withLatestFrom(this.tableState.query.values$())
    ).subscribe(([pagination, query]) => {
      if (this.wpListChecksumService.isQueryOutdated(query, pagination)) {
        this.wpListChecksumService.update(query, pagination);
        this.updateResultsVisibly();
      }
    });

    this.setupChangeObserver(this.wpTableFilters, true);
    this.setupChangeObserver(this.wpTableGroupBy);
    this.setupChangeObserver(this.wpTableSortBy);
    this.setupChangeObserver(this.wpTableSum);
    this.setupChangeObserver(this.wpTableTimeline);
    this.setupChangeObserver(this.wpTableHierarchies);
    this.setupChangeObserver(this.wpTableColumns);
    this.setupChangeObserver(this.wpTableHighlighting);
  }

  setupChangeObserver(service:WorkPackageQueryStateService, firstPage:boolean = false) {
    const queryState = this.tableState.query;

    this.tableState.ready.fireOnStateChange(service.state, 'Query loaded').values$().pipe(
      untilComponentDestroyed(this),
      filter(() => queryState.hasValue() && service.hasChanged(queryState.value!))
    ).subscribe(() => {
      const newQuery = queryState.value!;
      const triggerUpdate = service.applyToQuery(newQuery);
      this.tableState.query.putValue(newQuery);

      // Update the current checksum
      this.wpListChecksumService.updateIfDifferent(newQuery, this.wpTablePagination.current);

      // Update the page, if the change requires it
      if (triggerUpdate) {
        this.wpTableRefresh.request('Query updated by user', true, firstPage);
      }
    });
  }

  /**
   * Setup the listener for members of the table to request a refresh of the entire table
   * through the refresh service.
   */
  setupRefreshObserver() {
    this.wpTableRefresh.state.values$('Refresh listener in wp-list.controller').pipe(
      untilComponentDestroyed(this),
      auditTime(20)
    ).subscribe(([refreshVisibly, firstPage]) => {
      if (refreshVisibly) {
        debugLog('Refreshing work package results visibly.');
        this.updateResultsVisibly(firstPage);
      } else {
        debugLog('Refreshing work package results in the background.');
        this.updateResults();
      }
    });
  }

  updateResults():Promise<WorkPackageCollectionResource> {
    return this.wpListService.reloadCurrentResultsList();
  }

  updateResultsVisibly(firstPage:boolean = false) {
    if (firstPage) {
      this.loadingIndicator.table.promise = this.updateToFirstResultsPage();
    } else {
      this.loadingIndicator.table.promise = this.updateResults();
    }
  }

  updateToFirstResultsPage():Promise<WorkPackageCollectionResource> {
    return this.wpListService.loadCurrentResultsListFirstPage();
  }

  private updateQueryOnParamsChanges() {
    // Listen for param changes
    this.removeTransitionSubscription = this.$transitions.onSuccess({}, (transition):any => {
      let options = transition.options();

      // Avoid performing any changes when we're going to reload
      if (options.reload || (options.custom && options.custom.notify === false)) {
        return true;
      }

      const params = transition.params('to');
      let newChecksum = this.wpListService.getCurrentQueryProps(params);
      let newId = params.query_id && parseInt(params.query_id);

      this.wpListChecksumService
        .executeIfOutdated(newId,
          newChecksum,
          () => this.loadCurrentQuery());
    });
  }

  protected initialQueryLoading(loadingRequired:boolean) {
    if (loadingRequired) {
      this.wpTableRefresh.clear('Impending query loading.');
      this.loadCurrentQuery();
    }
  }

  protected loadCurrentQuery():Promise<any> {
    let loadingPromise = this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier);

    this.loadingIndicator.table.promise = loadingPromise;

    return loadingPromise;
  }
}
