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

@Injectable()
export class QuerySpaceService {
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
  ) {}
}
