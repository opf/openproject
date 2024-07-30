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

import { Directive, ElementRef } from '@angular/core';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import {
  OpTableActionsService,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import {
  WorkPackageViewRelationColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import {
  WorkPackageViewPaginationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import {
  WorkPackageViewGroupByService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import {
  WorkPackageViewHierarchiesService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import {
  WorkPackageViewSortByService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import {
  WorkPackageViewColumnsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import {
  WorkPackageViewFiltersService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import {
  WorkPackageViewTimelineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import {
  WorkPackageViewSumService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import {
  WorkPackageViewAdditionalElementsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-additional-elements.service';
import {
  WorkPackageViewHighlightingService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import {
  WorkPackageStatesInitializationService,
} from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import {
  WorkPackageRelationsHierarchyService,
} from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import {
  WorkPackageFiltersService,
} from 'core-app/features/work-packages/components/filters/wp-filters/wp-filters.service';
import {
  WorkPackageContextMenuHelperService,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import {
  WorkPackageInlineCreateService,
} from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import {
  WpChildrenInlineCreateService,
} from 'core-app/features/work-packages/components/wp-relations/embedded/children/wp-children-inline-create.service';
import {
  WpRelationInlineCreateService,
} from 'core-app/features/work-packages/components/wp-relations/embedded/relations/wp-relation-inline-create.service';
import {
  WorkPackagesListChecksumService,
} from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import {
  TableDragActionsRegistryService,
} from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import {
  WorkPackageViewOrderService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import {
  WorkPackageCardViewService,
} from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import {
  WorkPackageViewDisplayRepresentationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import {
  WorkPackageViewIncludeSubprojectsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import {
  WorkPackageViewHierarchyIdentationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { TimeEntryCreateService } from 'core-app/shared/components/time_entries/create/create.service';
import {
  WorkPackageViewCollapsedGroupsService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageService } from 'core-app/features/work-packages/services/work-package.service';
import {
  WorkPackageViewBaselineService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { TimeEntryEditService } from 'core-app/shared/components/time_entries/edit/edit.service';

/**
 * Directive to open a work package query 'space', an isolated injector hierarchy
 * that provides access to query-bound data and services, especially around the querySpace services.
 *
 * If you add services that depend on a table state, they should be provided here, not globally
 * in a module.
 */
@Directive({
  standalone: true,
  selector: '[opWorkPackageIsolatedQuerySpace]',
  providers: [
    // Override the hal notification service
    { provide: HalResourceNotificationService, useExisting: WorkPackageNotificationService },

    // Open the isolated space first, order is important here
    IsolatedQuerySpace,
    OpTableActionsService,

    // Work package table services
    WorkPackagesListChecksumService,
    WorkPackagesListService,
    WorkPackageViewRelationColumnsService,
    WorkPackageViewPaginationService,
    WorkPackageViewGroupByService,
    WorkPackageViewCollapsedGroupsService,
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
    WorkPackageViewIncludeSubprojectsService,
    WorkPackageViewOrderService,
    WorkPackageViewHierarchyIdentationService,
    WorkPackageViewBaselineService,
    CausedUpdatesService,

    WorkPackageService,
    WorkPackageRelationsHierarchyService,
    WorkPackageFiltersService,
    WorkPackageContextMenuHelperService,

    // Provide a separate service for creation events of WP Inline create
    // This can be hierarchically injected to provide isolated events on an embedded table
    WorkPackageInlineCreateService,
    WpChildrenInlineCreateService,
    WpRelationInlineCreateService,

    WorkPackageCardViewService,

    HalResourceEditingService,
    TimeEntryCreateService,
    TimeEntryEditService,
    WorkPackageCreateService,

    WorkPackageStatesInitializationService,

    // Table Drag & Drop actions
    TableDragActionsRegistryService,
  ],
})
export class WorkPackageIsolatedQuerySpaceDirective {
  constructor(
    public querySpace:IsolatedQuerySpace,
    elementRef:ElementRef,
  ) {
    debugLog('Opening isolated query space in %O', elementRef.nativeElement);
  }
}
