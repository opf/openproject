import { Injectable } from '@angular/core';
import {OpTableActionsService} from "core-components/wp-table/table-actions/table-actions.service";
import {WorkPackageViewRelationColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-relation-columns.service";
import {WorkPackageViewPaginationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-pagination.service";
import {WorkPackageViewGroupByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-group-by.service";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {WorkPackageViewSortByService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sort-by.service";
import {WorkPackageViewColumnsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-columns.service";
import {WorkPackageViewFiltersService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-filters.service";
import {WorkPackageViewTimelineService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-timeline.service";
import {WorkPackageViewSelectionService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import {WorkPackageViewSumService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-sum.service";
import {WorkPackageViewAdditionalElementsService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-additional-elements.service";
import {WorkPackageViewFocusService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service";
import {WorkPackageViewHighlightingService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";
import {WorkPackageViewDisplayRepresentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-display-representation.service";
import {WorkPackageViewOrderService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-order.service";
import {WorkPackageViewHierarchyIdentationService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service";
import {WorkPackageService} from "core-components/work-packages/work-package.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageFiltersService} from "core-components/filters/wp-filters/wp-filters.service";
import {WorkPackageContextMenuHelperService} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WpChildrenInlineCreateService} from "core-components/wp-relations/embedded/children/wp-children-inline-create.service";
import {WpRelationInlineCreateService} from "core-components/wp-relations/embedded/relations/wp-relation-inline-create.service";
import {WorkPackageCardViewService} from "core-components/wp-card-view/services/wp-card-view.service";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";
import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {TimeEntryCreateService} from "core-app/modules/time_entries/create/create.service";
import {TableDragActionsRegistryService} from "core-components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {filter, withLatestFrom} from "rxjs/operators";
import {WorkPackageQueryStateService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-base.service";
import {HalEvent, HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";

@Injectable()
export class QuerySpaceService extends UntilDestroyedMixin {
  queryId?:string;
  view = {
    relationColumns: this.relationColumns,
    pagination: this.pagination,
    groupBy: this.groupBy,
    hierarchies: this.hierarchies,
    sortBy: this.sortBy,
    columns: this.columns,
    filters: this.viewFilters,
    timeline: this.timeline,
    selection: this.selection,
    sum: this.sum,
    additionalElements: this.additionalElements,
    focus: this.focus,
    highlighting: this.highlighting,
    displayRepresentation: this.displayRepresentation,
    order: this.order,
    hierarchyIndentation: this.hierarchyIndentation,
  };
  workPackages = {
    service: this.service,
    relationsHierarchy: this.relationsHierarchy,
    filters: this.workPackageFilters,
    contextMenuHelper: this.contextMenuHelper,
    inlineCreate: this.inlineCreate,
    childrenInlineCreate: this.childrenInlineCreate,
    relationInlineCreate: this.relationInlineCreate,
    cardView: this.cardView,
    create: this.create,
    statesInitialization: this.statesInitialization,
    notification: this.notification,
    list: this.list,
    listChecksum: this.listChecksum,
  };

  constructor(
    // View services
    private relationColumns:WorkPackageViewRelationColumnsService,
    private pagination:WorkPackageViewPaginationService,
    private groupBy:WorkPackageViewGroupByService,
    private hierarchies:WorkPackageViewHierarchiesService,
    private sortBy:WorkPackageViewSortByService,
    private columns:WorkPackageViewColumnsService,
    private viewFilters:WorkPackageViewFiltersService,
    private timeline:WorkPackageViewTimelineService,
    private selection:WorkPackageViewSelectionService,
    private sum:WorkPackageViewSumService,
    private additionalElements:WorkPackageViewAdditionalElementsService,
    private focus:WorkPackageViewFocusService,
    private highlighting:WorkPackageViewHighlightingService,
    private displayRepresentation:WorkPackageViewDisplayRepresentationService,
    private order:WorkPackageViewOrderService,
    private hierarchyIndentation:WorkPackageViewHierarchyIdentationService,
    // Work packages service
    private service:WorkPackageService,
    private relationsHierarchy:WorkPackageRelationsHierarchyService,
    private workPackageFilters:WorkPackageFiltersService,
    private contextMenuHelper:WorkPackageContextMenuHelperService,
    private inlineCreate:WorkPackageInlineCreateService,
    private childrenInlineCreate:WpChildrenInlineCreateService,
    private relationInlineCreate:WpRelationInlineCreateService,
    private cardView:WorkPackageCardViewService,
    private create:WorkPackageCreateService,
    private statesInitialization:WorkPackageStatesInitializationService,
    private notification:WorkPackageNotificationService,
    private list:WorkPackagesListService,
    private listChecksum:WorkPackagesListChecksumService,
    // Others
    // TODO: Are this services needed here?
    private halResourceEditingService:HalResourceEditingService,
    private timeEntryCreateService:TimeEntryCreateService,
    private tableDragActionsRegistryService:TableDragActionsRegistryService,
    private opTableActionsService:OpTableActionsService,
    readonly query:IsolatedQuerySpace,
    private wpTablePagination:WorkPackageViewPaginationService,
    private currentProject:CurrentProjectService,
    private halEvents:HalEventsService,
    private queryParamListener:QueryParamListenerService,
    private loadingIndicatorService:LoadingIndicatorService,
  ) {
    super();
  }

  initialize(queryId?:string) {
    // TODO: Implement refresh when the component has queryId (nested querySpace?)
    this.queryId = queryId;

    // Load first page onInit
    this.refresh(true, true);

    // Listen to changes on the query state objects
    this.setupQueryObservers();

    // Listen for refresh changes
    this.setupRefreshObserver();

    if (!this.queryId) {
      // Load query on URL transitions
      this.queryParamListener
        .observe$
        .pipe(
          this.untilDestroyed()
        )
        .subscribe(() => this.refresh(true, true));
    }
  }

  refresh(firstPage?:boolean, showSpinner?:boolean):Promise<unknown> {
    firstPage = firstPage != null ?
      firstPage :
      !this.query.initialized.hasValue();
    const query = this.query.query.value;
    let promise:Promise<unknown>;

    if (firstPage || !query) {
      if (query) {
        promise = this.workPackages.list.reloadQuery(query, this.projectIdentifier).toPromise();
      } else {
        promise = this.workPackages.list.loadCurrentQueryFromParams(this.projectIdentifier);
      }
    } else {
      let pagination = this.workPackages.list.getPaginationInfo();

      promise = this.workPackages
                  .list
                  .loadQueryFromExisting(query, pagination, this.projectIdentifier)
                  .toPromise();
    }

    if (showSpinner) {
      return this.loadingIndicator = promise.then((loadedQuery:QueryResource) => {
        this.workPackages.statesInitialization.initialize(loadedQuery, loadedQuery.results);
        return this.additionalLoadingTime();
      });
    }

    return promise.then((loadedQuery:QueryResource) => {
      this.workPackages.statesInitialization.initialize(loadedQuery, loadedQuery.results);
    });
  }

  private setupQueryObservers() {
    this.wpTablePagination
      .updates$()
      .pipe(
        this.untilDestroyed(),
        withLatestFrom(this.query.query.values$())
      ).subscribe(([pagination, query]) => {
      if (this.workPackages.listChecksum.isQueryOutdated(query, pagination)) {
        this.workPackages.listChecksum.update(query, pagination);
        this.refresh(false, true);
      }
    });

    this.setupChangeObserver(this.view.filters, true);
    this.setupChangeObserver(this.view.groupBy);
    this.setupChangeObserver(this.view.sortBy);
    this.setupChangeObserver(this.view.sum);
    this.setupChangeObserver(this.view.timeline);
    this.setupChangeObserver(this.view.hierarchies);
    this.setupChangeObserver(this.view.columns);
    this.setupChangeObserver(this.view.highlighting);
    this.setupChangeObserver(this.view.order);
    this.setupChangeObserver(this.view.displayRepresentation);
  }

  /**
   * Listen to changes in the given service and reload the query / results if
   * the service requests that.
   *
   * @param service Work package query state service to listento
   * @param firstPage If the service requests a change, load the first page
   */
  protected setupChangeObserver(service:WorkPackageQueryStateService<unknown>, firstPage:boolean = false) {
    const queryState = this.query.query;

    service
      .updates$()
      .pipe(
        this.untilDestroyed(),
        filter(() => queryState.hasValue() && service.hasChanged(queryState.value!))
      )
      .subscribe(() => {
        const newQuery = queryState.value!;
        const triggerUpdate = service.applyToQuery(newQuery);
        this.query.query.putValue(newQuery);

        // Update the current checksum
        this.workPackages
          .listChecksum
          .updateIfDifferent(newQuery, this.wpTablePagination.current)
          .then(() => {
            // Update the page, if the change requires it
            if (triggerUpdate) {
              this.refresh(firstPage, true);
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
        filter((events:HalEvent[]) => this.filterRefreshEvents(events))
      )
      .subscribe((events:HalEvent[]) => {
        this.refresh();
      });
  }

  /**
   * Filter the given work package events for something interesting
   * @param events HalEvent[]
   *
   * @return {boolean} whether any of these events should trigger the view reloading
   */
  protected filterRefreshEvents(events:HalEvent[]):boolean {
    let rendered = new Set(this.query.renderedWorkPackageIds.getValueOr([]));

    for (let i = 0; i < events.length; i++) {
      const item = events[i];
      if (rendered.has(item.id) || item.eventType === 'created') {
        return true;
      }
    }

    return false;
  }

  /**
   * Set the loading indicator for this set instance
   * @param promise
   */
  protected set loadingIndicator(promise:Promise<unknown>) {
    this.loadingIndicatorService.table.promise = promise;
  }

  protected additionalLoadingTime():Promise<unknown> {
    return Promise.resolve();
  }
}
