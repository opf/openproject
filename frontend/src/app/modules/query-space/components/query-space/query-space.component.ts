import {Component, Input, OnInit} from '@angular/core';
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
import {OpTableActionsService} from "core-components/wp-table/table-actions/table-actions.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {CausedUpdatesService} from "core-app/modules/boards/board/caused-updates/caused-updates.service";
import {QuerySpaceService} from "core-app/modules/query-space/services/query-space/query-space.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";

@Component({
  selector: 'query-space',
  templateUrl: './query-space.component.html',
  styleUrls: ['./query-space.component.css'],
  providers: [
    QuerySpaceService,
    // View services
    WorkPackageViewRelationColumnsService,
    WorkPackageViewPaginationService,
    WorkPackageViewGroupByService,
    WorkPackageViewHierarchiesService,
    WorkPackageViewSortByService,
    WorkPackageViewColumnsService,
    WorkPackageViewFiltersService,
    WorkPackageViewTimelineService,
    WorkPackageViewSelectionService,
    WorkPackageViewSumService,
    WorkPackageViewAdditionalElementsService,
    WorkPackageViewFocusService,
    WorkPackageViewHighlightingService,
    WorkPackageViewDisplayRepresentationService,
    WorkPackageViewOrderService,
    WorkPackageViewHierarchyIdentationService,
    // Work packages services
    WorkPackageService,
    WorkPackageRelationsHierarchyService,
    WorkPackageFiltersService,
    WorkPackageContextMenuHelperService,
    WorkPackageInlineCreateService,
    WpChildrenInlineCreateService,
    WpRelationInlineCreateService,
    WorkPackageCardViewService,
    WorkPackageCreateService,
    WorkPackageStatesInitializationService,
    WorkPackageNotificationService,
    WorkPackagesListService,
    WorkPackagesListChecksumService,
    WorkPackagesListService,
    WorkPackagesListChecksumService,
    // Others
    // TODO: Are this services needed here?
    HalResourceEditingService,
    TimeEntryCreateService,
    TableDragActionsRegistryService,
    OpTableActionsService,
    IsolatedQuerySpace,
    CausedUpdatesService,
    QueryParamListenerService,
  ],
})
export class QuerySpaceComponent implements OnInit {
  @Input()
  queryId:string;

  constructor(
    readonly querySpaceService:QuerySpaceService,
  ) {}

  ngOnInit():void {
    this.querySpaceService.initialize(this.queryId);
  }
}
