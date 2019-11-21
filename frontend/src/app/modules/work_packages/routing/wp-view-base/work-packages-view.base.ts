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

import {ChangeDetectorRef, Injector, OnDestroy, OnInit} from '@angular/core';
import {StateService, TransitionService} from '@uirouter/core';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {untilComponentDestroyed} from 'ng2-rx-componentdestroyed';
import {filter, map, withLatestFrom} from 'rxjs/operators';
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {WorkPackageStaticQueriesService} from 'core-components/wp-query-select/wp-static-queries.service';
import {WorkPackageViewHighlightingService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";
import {States} from "core-components/states.service";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {WorkPackageViewSortByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import {WorkPackageViewGroupByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-group-by.service";
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import {WorkPackageViewSumService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sum.service";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {WorkPackageViewPaginationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-pagination.service";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";
import {WorkPackageQueryStateService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-base.service";
import {QueryDmService} from "core-app/modules/hal/dm-services/query-dm.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {WorkPackageViewOrderService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import {WorkPackageViewDisplayRepresentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {HalEvent, HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {DeviceService} from "core-app/modules/common/browser/device.service";

export abstract class WorkPackagesViewBase implements OnInit, OnDestroy {

  readonly $state:StateService = this.injector.get(StateService);
  readonly states:States = this.injector.get(States);
  readonly querySpace:IsolatedQuerySpace = this.injector.get(IsolatedQuerySpace);
  readonly authorisationService:AuthorisationService = this.injector.get(AuthorisationService);
  readonly wpTableColumns:WorkPackageViewColumnsService = this.injector.get(WorkPackageViewColumnsService);
  readonly wpTableHighlighting:WorkPackageViewHighlightingService = this.injector.get(WorkPackageViewHighlightingService);
  readonly wpTableSortBy:WorkPackageViewSortByService = this.injector.get(WorkPackageViewSortByService);
  readonly wpTableGroupBy:WorkPackageViewGroupByService = this.injector.get(WorkPackageViewGroupByService);
  readonly wpTableFilters:WorkPackageViewFiltersService = this.injector.get(WorkPackageViewFiltersService);
  readonly wpTableSum:WorkPackageViewSumService = this.injector.get(WorkPackageViewSumService);
  readonly wpTableTimeline:WorkPackageViewTimelineService = this.injector.get(WorkPackageViewTimelineService);
  readonly wpTableHierarchies:WorkPackageViewHierarchiesService = this.injector.get(WorkPackageViewHierarchiesService);
  readonly wpTablePagination:WorkPackageViewPaginationService = this.injector.get(WorkPackageViewPaginationService);
  readonly wpTableOrder:WorkPackageViewOrderService = this.injector.get(WorkPackageViewOrderService);
  readonly wpListService:WorkPackagesListService = this.injector.get(WorkPackagesListService);
  readonly wpListChecksumService:WorkPackagesListChecksumService = this.injector.get(WorkPackagesListChecksumService);
  readonly loadingIndicatorService:LoadingIndicatorService = this.injector.get(LoadingIndicatorService);
  readonly $transitions:TransitionService = this.injector.get(TransitionService);
  readonly I18n:I18nService = this.injector.get(I18nService);
  readonly wpStaticQueries:WorkPackageStaticQueriesService = this.injector.get(WorkPackageStaticQueriesService);
  readonly QueryDm:QueryDmService = this.injector.get(QueryDmService);
  readonly wpStatesInitialization:WorkPackageStatesInitializationService = this.injector.get(WorkPackageStatesInitializationService);
  readonly cdRef:ChangeDetectorRef = this.injector.get(ChangeDetectorRef);
  readonly wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService = this.injector.get(WorkPackageViewDisplayRepresentationService);
  readonly halEvents:HalEventsService = this.injector.get(HalEventsService);
  readonly deviceService:DeviceService = this.injector.get(DeviceService);


  constructor(protected injector:Injector) {
  }

  ngOnInit() {
    // Listen to changes on the query state objects
    this.setupQueryObservers();

    // Listen for refresh changes
    this.setupRefreshObserver();
  }

  ngOnDestroy():void {
    // Nothing to do
  }

  private setupQueryObservers() {
    this.wpTablePagination
      .updates$()
      .pipe(
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
    this.setupChangeObserver(this.wpTableOrder);
    this.setupChangeObserver(this.wpDisplayRepresentation);
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

    service
      .updates$()
      .pipe(
        untilComponentDestroyed(this),
        filter(() => queryState.hasValue() && service.hasChanged(queryState.value!))
      )
      .subscribe(() => {
        const newQuery = queryState.value!;
        const triggerUpdate = service.applyToQuery(newQuery);
        this.querySpace.query.putValue(newQuery);

        // Update the current checksum
        this.wpListChecksumService
          .updateIfDifferent(newQuery, this.wpTablePagination.current)
          .then(() => {
            // Update the page, if the change requires it
            if (triggerUpdate) {
              this.refresh(true, firstPage);
            }
          });
      });
  }

  /**
   * Setup the listener for members of the table to request a refresh of the entire table
   * through the refresh service.
   */
  protected setupRefreshObserver() {
    this.halEvents
      .aggregated$('WorkPackage')
      .pipe(
        untilComponentDestroyed(this),
        filter((events:HalEvent[]) => this.filterRefreshEvents(events))
      )
      .subscribe((events:HalEvent[]) => {
        this.refresh(false, false);
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
   * Filter the given work package events for something interesting
   * @param events HalEvent[]
   *
   * @return {boolean} whether any of these events should trigger the view reloading
   */
  protected filterRefreshEvents(events:HalEvent[]):boolean {
    let rendered = new Set(this.querySpace.renderedWorkPackageIds.getValueOr([]));

    for (let i = 0; i < events.length; i++) {
      const item = events[i];
      if (rendered.has(item.id) || item.eventType === 'created') {
        return true;
      }
    }

    return false;
  }
}
