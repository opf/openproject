import { TestBed } from '@angular/core/testing';
import { QuerySpaceService } from './query-space.service';
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
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {QueryParamListenerService} from "core-components/wp-query/query-param-listener.service";
import {States} from "core-components/states.service";
import {HttpClientTestingModule} from "@angular/common/http/testing";
import {WorkPackageRelationsService} from "core-components/wp-relations/wp-relations.service";
import {PaginationService} from "core-components/table-pagination/pagination-service";
import {TransitionService} from "@uirouter/core";

xdescribe('QuerySpaceService', () => {
  let service:QuerySpaceService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule,
      ],
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
        // Work packages service
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
        // Others
        HalResourceEditingService,
        TimeEntryCreateService,
        TableDragActionsRegistryService,
        OpTableActionsService,
        IsolatedQuerySpace,
        WorkPackageViewPaginationService,
        CurrentProjectService,
        HalEventsService,
        QueryParamListenerService,
        // Nested dependencies
        States,
        WorkPackageRelationsService,
        PaginationService,
        // TransitionService,
      ]
    });
    service = TestBed.inject(QuerySpaceService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
