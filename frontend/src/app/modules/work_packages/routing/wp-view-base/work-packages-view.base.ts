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
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {auditTime, filter, take, withLatestFrom} from 'rxjs/operators';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {States} from "core-components/states.service";
import {
  WorkPackageTableRefreshRequest,
  WorkPackageTableRefreshService
} from "core-components/wp-table/wp-table-refresh-request.service";
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
import {WorkPackageFiltersService} from "core-components/filters/wp-filters/wp-filters.service";

export abstract class WorkPackagesViewBase implements OnInit, OnDestroy {

  readonly $state:StateService = this.injector.get(StateService);
  readonly states:States = this.injector.get(States);
  readonly querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  readonly authorisationService:AuthorisationService = this.injector.get(AuthorisationService);
  readonly wpTableRefresh:WorkPackageTableRefreshService = this.injector.get(WorkPackageTableRefreshService);
  readonly wpTableColumns:WorkPackageTableColumnsService = this.injector.get(WorkPackageTableColumnsService);
  readonly wpTableHighlighting:WorkPackageTableHighlightingService = this.injector.get(WorkPackageTableHighlightingService);
  readonly wpTableSortBy:WorkPackageTableSortByService = this.injector.get(WorkPackageTableSortByService);
  readonly wpTableGroupBy:WorkPackageTableGroupByService = this.injector.get(WorkPackageTableGroupByService);
  readonly wpTableFilters:WorkPackageTableFiltersService = this.injector.get(WorkPackageTableFiltersService);
  readonly wpTableSum:WorkPackageTableSumService = this.injector.get(WorkPackageTableSumService);
  readonly wpTableTimeline:WorkPackageTableTimelineService = this.injector.get(WorkPackageTableTimelineService);
  readonly wpTableHierarchies:WorkPackageTableHierarchiesService = this.injector.get(WorkPackageTableHierarchiesService);
  readonly wpTablePagination:WorkPackageTablePaginationService = this.injector.get(WorkPackageTablePaginationService);
  readonly wpListService:WorkPackagesListService = this.injector.get(WorkPackagesListService);
  readonly wpListChecksumService:WorkPackagesListChecksumService = this.injector.get(WorkPackagesListChecksumService);
  readonly loadingIndicatorService:LoadingIndicatorService = this.injector.get(LoadingIndicatorService);
  readonly $transitions:TransitionService = this.injector.get(TransitionService);
  readonly I18n:I18nService = this.injector.get(I18nService);
  readonly wpStaticQueries:WorkPackageStaticQueriesService = this.injector.get(WorkPackageStaticQueriesService);

  constructor(protected injector:Injector) {
  }

  ngOnInit() {
    // Listen to changes on the query state objects
    this.setupQueryObservers();

    // Listen for refresh changes
    this.setupRefreshObserver();
  }

  ngOnDestroy():void {
    this.wpTableRefresh.clear('Table controller scope destroyed.');
  }

  private setupQueryObservers() {
    this.querySpace.ready.fireOnStateChange(this.wpTablePagination.state,
      'Query loaded').values$().pipe(
      untilComponentDestroyed(this),
      withLatestFrom(this.querySpace.query.values$())
    ).subscribe(([pagination, query]) => {
      if (this.wpListChecksumService.isQueryOutdated(query, pagination)) {
        this.wpListChecksumService.update(query, pagination);
        this.refresh(true, false);
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

  /**
   * Listen to changes in the given service and reload the query / results if
   * the service requests that.
   *
   * @param service Work package query state service to listento
   * @param firstPage If the service requests a change, load the first page
   */
  protected setupChangeObserver(service:WorkPackageQueryStateService<unknown>, firstPage:boolean = false) {
    const queryState = this.querySpace.query;

    this.querySpace.ready
      .fireOnStateChange(service.readonlyState, 'Query loaded')
      .values$()
      .pipe(
        untilComponentDestroyed(this),
        filter(() => queryState.hasValue() && service.hasChanged(queryState.value!))
      ).subscribe(() => {
      const newQuery = queryState.value!;
      const triggerUpdate = service.applyToQuery(newQuery);
      this.querySpace.query.putValue(newQuery);

      // Update the current checksum
      this.wpListChecksumService.updateIfDifferent(newQuery, this.wpTablePagination.current);

      // Update the page, if the change requires it
      if (triggerUpdate) {
        this.wpTableRefresh.request(
          'Query updated by user',
          'update',
          { visible: true, firstPage: firstPage }
        );
      }
    });
  }

  /**
   * Setup the listener for members of the table to request a refresh of the entire table
   * through the refresh service.
   */
  protected setupRefreshObserver() {
    this.wpTableRefresh.state.values$('Refresh listener in wp-set.component').pipe(
      untilComponentDestroyed(this),
      filter(request => this.filterRefreshRequest(request)),
      auditTime(20)
    ).subscribe((request) => {
      debugLog('Refreshing work package results.');
      this.refresh(request.visible, request.firstPage);
    });
  }


  /**
   * Refresh the set of results,
   * showing the loading indicator if visibly is set.
   *
   * @param A refresh request
   */
  public abstract refresh(visibly:boolean, firstPage:boolean):Promise<unknown>;


  /**
   * Set the loading indicator for this set instance
   * @param promise
   */
  protected abstract set loadingIndicator(promise:Promise<unknown>);

  /**
   * Filter the given refresh request?
   * @param request {WorkPackageTableRefreshRequest}
   * @return {boolean} whether the request should be processed.
   */
  protected filterRefreshRequest(request:WorkPackageTableRefreshRequest):boolean {
    return true;
  }
}
