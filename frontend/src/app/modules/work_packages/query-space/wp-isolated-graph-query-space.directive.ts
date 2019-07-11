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

import {Directive, ElementRef, Injector} from '@angular/core';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {OpTableActionsService} from "core-components/wp-table/table-actions/table-actions.service";
import {WorkPackageTableRelationColumnsService} from "core-components/wp-fast-table/state/wp-table-relation-columns.service";
import {WorkPackageTablePaginationService} from "core-components/wp-fast-table/state/wp-table-pagination.service";
import {WorkPackageTableGroupByService} from "core-components/wp-fast-table/state/wp-table-group-by.service";
import {WorkPackageTableHierarchiesService} from "core-components/wp-fast-table/state/wp-table-hierarchy.service";
import {WorkPackageTableSortByService} from "core-components/wp-fast-table/state/wp-table-sort-by.service";
import {WorkPackageTableColumnsService} from "core-components/wp-fast-table/state/wp-table-columns.service";
import {WorkPackageTableFiltersService} from "core-components/wp-fast-table/state/wp-table-filters.service";
import {WorkPackageTableTimelineService} from "core-components/wp-fast-table/state/wp-table-timeline.service";
import {WorkPackageTableSelection} from "core-components/wp-fast-table/state/wp-table-selection.service";
import {WorkPackageTableSumService} from "core-components/wp-fast-table/state/wp-table-sum.service";
import {WorkPackageTableAdditionalElementsService} from "core-components/wp-fast-table/state/wp-table-additional-elements.service";
import {WorkPackageTableRefreshService} from "core-components/wp-table/wp-table-refresh-request.service";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {IWorkPackageCreateServiceToken} from "core-components/wp-new/wp-create.service.interface";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";
import {WorkPackageStatesInitializationService} from "core-components/wp-list/wp-states-initialization.service";
import {WorkPackageTableFocusService} from "core-components/wp-fast-table/state/wp-table-focus.service";
import {IWorkPackageEditingServiceToken} from "core-components/wp-edit-form/work-package-editing.service.interface";
import {WorkPackageEditingService} from "core-components/wp-edit-form/work-package-editing-service";
import {WorkPackagesListService} from "core-components/wp-list/wp-list.service";
import {WorkPackageService} from "core-components/work-packages/work-package.service";
import {WorkPackageRelationsHierarchyService} from "core-components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service";
import {WorkPackageFiltersService} from "core-components/filters/wp-filters/wp-filters.service";
import {WorkPackageContextMenuHelperService} from "core-components/wp-table/context-menu-helper/wp-context-menu-helper.service";
import {WorkPackageInlineCreateService} from "core-components/wp-inline-create/wp-inline-create.service";
import {WpChildrenInlineCreateService} from "core-components/wp-relations/embedded/children/wp-children-inline-create.service";
import {WpRelationInlineCreateService} from "core-components/wp-relations/embedded/relations/wp-relation-inline-create.service";
import {WorkPackagesListChecksumService} from "core-components/wp-list/wp-list-checksum.service";
import {debugLog} from "core-app/helpers/debug_output";
import {PortalCleanupService} from "core-app/modules/fields/display/display-portal/portal-cleanup.service";
import {TableDragActionsRegistryService} from "core-components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service";
import {ReorderQueryService} from "core-app/modules/common/drag-and-drop/reorder-query.service";
import {IsolatedGraphQuerySpace} from "core-app/modules/work_packages/query-space/isolated-graph-query-space";
import {WorkPackageIsolatedQuerySpaceDirective} from "core-app/modules/work_packages/query-space/wp-isolated-query-space.directive";

export const WpIsolatedGraphQuerySpaceProviders = [
  // Open the isolated space first, order is important here
  { provide: IsolatedQuerySpace, useClass: IsolatedGraphQuerySpace },
  OpTableActionsService,

  WorkPackageTableRefreshService,

  // Work package table services
  WorkPackagesListChecksumService,
  WorkPackagesListService,
  WorkPackageTableRelationColumnsService,
  WorkPackageTablePaginationService,
  WorkPackageTableGroupByService,
  WorkPackageTableHierarchiesService,
  WorkPackageTableSortByService,
  WorkPackageTableColumnsService,
  WorkPackageTableFiltersService,
  WorkPackageTableTimelineService,
  WorkPackageTableSelection,
  WorkPackageTableSumService,
  WorkPackageTableAdditionalElementsService,
  WorkPackageTableFocusService,
  WorkPackageTableHighlightingService,
  WorkPackageService,
  WorkPackageRelationsHierarchyService,
  WorkPackageFiltersService,
  WorkPackageContextMenuHelperService,

  // Provide a separate service for creation events of WP Inline create
  // This can be hierarchically injected to provide isolated events on an embedded table
  WorkPackageInlineCreateService,
  WpChildrenInlineCreateService,
  WpRelationInlineCreateService,

  // Provide both serves with tokens to avoid tight dependency cycles
  { provide: IWorkPackageCreateServiceToken, useClass: WorkPackageCreateService },
  { provide: IWorkPackageEditingServiceToken, useClass: WorkPackageEditingService },

  WorkPackageStatesInitializationService,
  ReorderQueryService,

  PortalCleanupService,

  // Table Drag & Drop actions
  TableDragActionsRegistryService,
];



/**
 * Directive to open a work package query 'space', an isolated injector hierarchy
 * that provides access to query-bound data and services, especially around the querySpace services.
 *
 * If you add services that depend on a table state, they should be provided here, not globally
 * in a module.
 */
@Directive({
  selector: '[wp-isolated-graph-query-space]',
  providers: WpIsolatedGraphQuerySpaceProviders
})
export class WorkPackageIsolatedGraphQuerySpaceDirective extends WorkPackageIsolatedQuerySpaceDirective {

  //constructor(private elementRef:ElementRef,
  //            public querySpace:IsolatedQuerySpace,
  //            private injector:Injector) {
  //  debugLog("Opening isolated query space %O in %O", injector, elementRef.nativeElement);
  //}
}
