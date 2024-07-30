//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { ChangeDetectorRef, Directive, Injector, OnDestroy, OnInit } from '@angular/core';
import { StateService, TransitionService } from '@uirouter/core';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { filter, take, withLatestFrom } from 'rxjs/operators';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import {
  WorkPackageViewHighlightingService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { States } from 'core-app/core/states/states.service';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {
  WorkPackageViewSortByService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import {
  WorkPackageViewGroupByService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import {
  WorkPackageViewSumService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import {
  WorkPackageViewTimelineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import {
  WorkPackageViewHierarchiesService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import {
  WorkPackageViewPaginationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import {
  WorkPackagesListChecksumService,
} from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import {
  WorkPackageQueryStateService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import {
  WorkPackageStatesInitializationService,
} from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import {
  WorkPackageViewOrderService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import {
  WorkPackageViewDisplayRepresentationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import {
  WorkPackageViewIncludeSubprojectsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { HalEvent, HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  WorkPackageViewBaselineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';

@Directive()
export abstract class WorkPackagesViewBase extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @InjectField() $state:StateService;

  @InjectField() states:States;

  @InjectField() querySpace:IsolatedQuerySpace;

  @InjectField() authorisationService:AuthorisationService;

  @InjectField() wpTableColumns:WorkPackageViewColumnsService;

  @InjectField() wpTableHighlighting:WorkPackageViewHighlightingService;

  @InjectField() wpTableSortBy:WorkPackageViewSortByService;

  @InjectField() wpTableGroupBy:WorkPackageViewGroupByService;

  @InjectField() wpTableFilters:WorkPackageViewFiltersService;

  @InjectField() wpTableSum:WorkPackageViewSumService;

  @InjectField() wpTableTimeline:WorkPackageViewTimelineService;

  @InjectField() wpTableHierarchies:WorkPackageViewHierarchiesService;

  @InjectField() wpTablePagination:WorkPackageViewPaginationService;

  @InjectField() wpTableOrder:WorkPackageViewOrderService;

  @InjectField() wpListService:WorkPackagesListService;

  @InjectField() wpListChecksumService:WorkPackagesListChecksumService;

  @InjectField() loadingIndicatorService:LoadingIndicatorService;

  @InjectField() $transitions:TransitionService;

  @InjectField() I18n!:I18nService;

  @InjectField() opStaticQueries:StaticQueriesService;

  @InjectField() wpStatesInitialization:WorkPackageStatesInitializationService;

  @InjectField() cdRef:ChangeDetectorRef;

  @InjectField() wpDisplayRepresentation:WorkPackageViewDisplayRepresentationService;

  @InjectField() wpIncludeSubprojects:WorkPackageViewIncludeSubprojectsService;

  @InjectField() wpTableBaseline:WorkPackageViewBaselineService;

  @InjectField() halEvents:HalEventsService;

  @InjectField() deviceService:DeviceService;

  @InjectField() currentProject:CurrentProjectService;

  @InjectField() actions$:ActionsService;

  /** Determine when query is initially loaded */
  queryLoaded = false;

  /** Remember explicitly when this component was destroyed */
  destroyed = false;

  constructor(public injector:Injector) {
    super();
  }

  ngOnInit() {
    // Listen to changes on the query state objects
    this.setupQueryObservers();

    // Listen for refresh changes
    this.setupRefreshObserver();

    // Mark tableInformationLoaded when initially loading done
    this.setupQueryLoadedListener();
  }

  private setupQueryObservers() {
    this.wpTablePagination
      .updates$()
      .pipe(
        this.untilDestroyed(),
        withLatestFrom(this.querySpace.query.values$()),
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
    this.setupChangeObserver(this.wpIncludeSubprojects);
    this.setupChangeObserver(this.wpTableBaseline);
  }

  /**
   * Listen to changes in the given service and reload the query / results if
   * the service requests that.
   *
   * @param service Work package query state service to listento
   * @param firstPage If the service requests a change, load the first page
   */
  protected setupChangeObserver(service:WorkPackageQueryStateService<unknown>, firstPage = false) {
    const queryState = this.querySpace.query;

    service
      .updates$()
      .pipe(
        this.untilDestroyed(),
        filter(() => queryState.hasValue() && service.hasChanged(queryState.value!)),
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

  public get projectIdentifier() {
    return this.currentProject.identifier || undefined;
  }

  /**
   * Setup the listener for members of the table to request a refresh of the entire table
   * through the refresh service.
   */
  protected setupRefreshObserver() {
    this.halEvents
      .aggregated$('WorkPackage')
      .pipe(
        this.untilDestroyed(),
        filter((events:HalEvent[]) => this.filterRefreshEvents(events)),
      )
      .subscribe((events:HalEvent[]) => {
        this.refresh(false, false);
      });

    this
      .actions$
      .ofType(tableRefreshRequest)
      .pipe(
        this.untilDestroyed(),
      )
      .subscribe(() => {
        this.refresh(false, false);
      });
  }

  /**
   * Refresh the set of results,
   * showing the loading indicator if visibly is set.
   *
   * @param A refresh request
   */
  public abstract refresh(visibly:boolean, firstPage:boolean):void;

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
    const source:string[] = this.querySpace.renderedWorkPackageIds.value
      || this.querySpace.results.value?.elements.map((el) => el.id as string)
      || [];

    const rendered = new Set(source);

    for (let i = 0; i < events.length; i++) {
      const item = events[i];
      if (rendered.has(item.id) || item.eventType === 'created') {
        return true;
      }
    }

    return false;
  }

  protected setupQueryLoadedListener() {
    this
      .querySpace
      .initialized
      .values$()
      .pipe(
        take(1),
        filter(() => !this.componentDestroyed),
      )
      .subscribe(() => {
        this.queryLoaded = true;
        this.cdRef.detectChanges();
      });
  }
}
