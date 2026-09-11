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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { fireEvent } from '@testing-library/dom';
import { EventEmitter, Injector, Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { StateService } from '@uirouter/core';
import { firstValueFrom } from 'rxjs';
import { skip, take } from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { States } from 'core-app/core/states/states.service';
import { CausedUpdatesService } from 'core-app/features/boards/board/caused-updates/caused-updates.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { TableDragActionsRegistryService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-actions-registry.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject,
} from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { WorkPackageTimelineTableController } from 'core-app/features/work-packages/components/wp-table/timeline/container/wp-timeline-container.directive';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewOutputs } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';
import { WorkPackageViewBaseService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { WorkPackageViewRelationColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-relation-columns.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { DragAndDropService } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { TableHandlerRegistry } from '../handlers/table-handler-registry';
import { WorkPackageTable } from '../wp-fast-table';
import { buildWorkPackage, WorkPackageFixture } from './work-package-fixture';

export interface TableHarnessOptions {
  workPackages:WorkPackageFixture[];
  columns?:string[];
  configuration?:WorkPackageTableConfigurationObject;
}

export interface TableHarness {
  readonly table:WorkPackageTable;
  readonly tbody:HTMLTableSectionElement;
  readonly container:HTMLElement;
  readonly injector:Injector;
  readonly querySpace:IsolatedQuerySpace;
  readonly selection:WorkPackageViewSelectionService;
  readonly focus:WorkPackageViewFocusService;
  readonly outputs:WorkPackageViewOutputs;
  render(workPackages?:WorkPackageFixture[]):Promise<RenderedWorkPackage[]>;
  rows():HTMLTableRowElement[];
  row(workPackageId:string):HTMLTableRowElement;
  click(workPackageId:string, init?:MouseEventInit):void;
  destroy():void;
}

const harnessConfiguration:WorkPackageTableConfigurationObject = {
  actionsColumnEnabled: false,
  columnMenuEnabled: false,
  contextMenuEnabled: false,
  inlineCreateEnabled: false,
  dragAndDropEnabled: false,
};

export function buildTable(options:TableHarnessOptions):TableHarness {
  TestBed.configureTestingModule({ providers: harnessProviders() });

  const injector = TestBed.inject(Injector);
  const querySpace = TestBed.inject(IsolatedQuerySpace);
  const states = TestBed.inject(States);
  const dom = buildDom();

  initializeViewServices(injector, buildQuery(options.columns ?? ['id', 'subject']));

  const table = new WorkPackageTable(
    injector,
    dom.wrapper,
    dom.scroll,
    dom.tbody,
    dom.timelineBody,
    {} as WorkPackageTimelineTableController,
    new WorkPackageTableConfiguration({ ...harnessConfiguration, ...options.configuration }),
  );

  const outputs:WorkPackageViewOutputs = {
    selectionChanged: new EventEmitter<string[]>(),
    itemClicked: new EventEmitter<{ workPackageId:string, double:boolean }>(),
    stateLinkClicked: new EventEmitter<{ workPackageId:string, requestedState:string }>(),
  };
  new TableHandlerRegistry(injector).attachTo({ workPackageTable: table, ...outputs });

  let fixtures = options.workPackages;

  return {
    table,
    tbody: dom.tbody,
    container: dom.container,
    injector,
    querySpace,
    selection: TestBed.inject(WorkPackageViewSelectionService),
    focus: TestBed.inject(WorkPackageViewFocusService),
    outputs,

    render(workPackages = fixtures) {
      fixtures = workPackages;
      const resources = workPackages.map(buildWorkPackage);
      resources.forEach((wp) => states.workPackages.get(wp.id!).putValue(wp));

      const rendered = firstValueFrom(
        querySpace.tableRendered.values$().pipe(skip(querySpace.tableRendered.hasValue() ? 1 : 0), take(1)),
      );
      querySpace.results.putValue({ elements: resources } as WorkPackageCollectionResource);
      querySpace.initialized.putValue(null);

      return rendered;
    },

    rows() {
      return Array.from(dom.tbody.querySelectorAll<HTMLTableRowElement>('tr.wp-table--row'));
    },

    row(workPackageId) {
      const row = dom.tbody.querySelector<HTMLTableRowElement>(`tr.wp-table--row[data-work-package-id="${workPackageId}"]`);
      if (!row) {
        throw new Error(`No rendered row for work package ${workPackageId}`);
      }
      return row;
    },

    click(workPackageId, init = {}) {
      const row = this.row(workPackageId);
      const target = row.querySelector('td') ?? row;
      fireEvent.click(target, init);
    },

    destroy() {
      querySpace.stopAllSubscriptions.next();
      dom.wrapper.remove();
    },
  };
}

function harnessProviders() {
  return [
    States,
    IsolatedQuerySpace,
    ActionsService,
    WorkPackageViewSelectionService,
    WorkPackageViewFocusService,
    WorkPackageViewColumnsService,
    WorkPackageViewSortByService,
    WorkPackageViewGroupByService,
    WorkPackageViewCollapsedGroupsService,
    WorkPackageViewHierarchiesService,
    WorkPackageViewTimelineService,
    WorkPackageViewHighlightingService,
    WorkPackageViewRelationColumnsService,
    WorkPackageViewOrderService,
    {
      provide: ApiV3Service,
      useValue: { work_packages: { cache: { current: (_id:string, fallback:unknown) => fallback } } },
    },
    {
      provide: SchemaCacheService,
      useValue: { of: () => ({ ofProperty: () => undefined, mappedName: (attribute:string) => attribute }) },
    },
    { provide: I18nService, useValue: { t: (key:string) => key, locale: 'en' } },
    { provide: HalResourceService, useValue: {} },
    {
      provide: HalResourceEditingService,
      useValue: {
        typedState: () => ({ hasValue: () => false, value: undefined }),
        stopEditing: () => undefined,
      },
    },
    { provide: WorkPackageRelationsService, useValue: { state: () => ({ hasValue: () => false, value: undefined }) } },
    { provide: OPContextMenuService, useValue: { close: () => undefined, show: () => undefined } },
    { provide: BannersService, useValue: { eeShowBanners: false } },
    { provide: PathHelperService, useValue: {} },
    { provide: CausedUpdatesService, useValue: { add: () => undefined } },
    { provide: StateService, useValue: { current: { name: 'work-packages.partitioned.list' }, href: () => '' } },
    { provide: UrlParamsService, useValue: { currentDetailsRouteParams: () => null, basePathWithoutDetails: () => '' } },
    { provide: KeepTabService, useValue: { currentDetailsTab: 'overview', currentShowTab: 'activity' } },
    { provide: FocusHelperService, useValue: { focus: () => undefined } },
    { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false } },
    { provide: DragAndDropService, useValue: null },
    { provide: TableDragActionsRegistryService, useValue: { get: () => ({}) } },
  ];
}

function buildDom() {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = `
    <div class="work-packages-tabletimeline--table-side">
      <div class="work-package-table--container">
        <table class="work-package-table"><tbody class="work-package--results-tbody"></tbody></table>
      </div>
    </div>
    <div class="work-packages-tabletimeline--timeline-side"><div class="wp-table-timeline--body"></div></div>
  `;
  document.body.appendChild(wrapper);

  return {
    wrapper,
    container: wrapper.querySelector<HTMLElement>('.work-packages-tabletimeline--table-side')!,
    scroll: wrapper.querySelector<HTMLElement>('.work-package-table--container')!,
    tbody: wrapper.querySelector<HTMLTableSectionElement>('tbody')!,
    timelineBody: wrapper.querySelector<HTMLElement>('.wp-table-timeline--body')!,
  };
}

function buildQuery(columns:string[]):QueryResource {
  return {
    columns: columns.map((id) => ({ id, name: id, _type: 'QueryColumn', href: `/api/v3/queries/columns/${id}` })),
    sortBy: [],
    groupBy: null,
    showHierarchies: false,
    highlightingMode: 'inline',
    highlightedAttributes: [],
    timelineVisible: false,
    timelineZoomLevel: 'days',
    timelineLabels: undefined,
  } as unknown as QueryResource;
}

function initializeViewServices(injector:Injector, query:QueryResource) {
  const results = { elements: [] } as unknown as WorkPackageCollectionResource;
  const services:Type<WorkPackageViewBaseService<unknown>>[] = [
    WorkPackageViewColumnsService,
    WorkPackageViewSortByService,
    WorkPackageViewGroupByService,
    WorkPackageViewCollapsedGroupsService,
    WorkPackageViewTimelineService,
    WorkPackageViewHierarchiesService,
    WorkPackageViewHighlightingService,
  ];
  services.forEach((token) => injector.get(token).initialize(query, results));
}
