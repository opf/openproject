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
import {
  createEnvironmentInjector, EnvironmentInjector, EventEmitter, Injector, Type,
} from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { StateService } from '@uirouter/core';
import { firstValueFrom, of, Subject } from 'rxjs';
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
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { TableDragActionService } from 'core-app/features/work-packages/components/wp-table/drag-and-drop/actions/table-drag-action.service';
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
import { DragAndDropService, DragMember } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import type { Edge } from 'core-common/drag-and-drop/reorder';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import { rowGroupClassName } from '../builders/modes/grouped/grouped-classes.constants';
import { TableHandlerRegistry } from '../handlers/table-handler-registry';
import { locatePredecessorBySelector } from '../helpers/wp-table-row-helpers';
import { WorkPackageTable } from '../wp-fast-table';
import { buildGroup, buildWorkPackage, GroupFixture, WorkPackageFixture } from './work-package-fixture';
import { EditingPortalService } from 'core-app/shared/components/fields/edit/editing-portal/editing-portal-service';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';

export interface TableHarnessOptions {
  workPackages:WorkPackageFixture[];
  columns?:string[];
  /** Renders the table grouped by `groupBy` (default `status`) with one header row per group. */
  groups?:GroupFixture[];
  groupBy?:string;
  showHierarchies?:boolean;
  configuration?:WorkPackageTableConfigurationObject;
  /** Keeps production defaults for every setting but the extra columns the harness cannot build. */
  productionDefaults?:boolean;
  /** Overrides for the drag action service the drop handler resolves. */
  dragAction?:Partial<TableDragActionService>;
  /** Makes `subject` inline-editable; `formWritable: false` has the loaded form refuse the field. */
  editing?:{ formWritable?:boolean };
  /** The application-wide resource cache; pass one instance to tables that share a page. */
  states?:States;
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
  /** Resolves with the next completed table render. */
  nextRender():Promise<RenderedWorkPackage[]>;
  rows():HTMLTableRowElement[];
  row(workPackageId:string):HTMLTableRowElement;
  groupHeaderOf(row:HTMLElement):HTMLTableRowElement|null;
  /** Fresh lookup; group headers are replaced on every collapse toggle. */
  groupHeader(index:number):HTMLTableRowElement;
  rowIds():string[];
  /** Work-package entries of the rendered state, in order, as `[workPackageId, hidden]`. */
  renderedState():[string, boolean][];
  click(workPackageId:string, init?:MouseEventInit):void;
  /** Tells the registered drag member a drag of the given row has begun. */
  dragStart(workPackageId:string):void;
  /** Feeds a drop to the registered drag member; resolves with the transaction's `complete` value. */
  drop(sourceId:string, targetId:string|null, edge:Edge|null):Promise<boolean>;
  addRelationRow(workPackageId:string, afterId:string):HTMLTableRowElement;
  destroy():Promise<void>;
}

const harnessConfiguration:WorkPackageTableConfigurationObject = {
  actionsColumnEnabled: false,
  columnMenuEnabled: false,
  contextMenuEnabled: false,
  inlineCreateEnabled: false,
  dragAndDropEnabled: false,
};

const unbuildableColumns:WorkPackageTableConfigurationObject = {
  actionsColumnEnabled: false,
  columnMenuEnabled: false,
  dragAndDropEnabled: false,
};

export function buildTable(options:TableHarnessOptions):TableHarness {
  const dragService = new FakeDragAndDropService();
  const injector = createEnvironmentInjector(harnessProviders(dragService, options), TestBed.inject(EnvironmentInjector));
  injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
  const querySpace = injector.get(IsolatedQuerySpace);
  const states = injector.get(States);
  const dom = buildDom();

  const groupBy = options.groupBy ?? 'status';
  const query = buildQuery(options.columns ?? ['id', 'subject'], options.groups ? groupBy : null, options.showHierarchies ?? false);
  querySpace.query.putValue(query);
  querySpace.groups.putValue((options.groups ?? []).map((group, index) => buildGroup(group, groupBy, index)));
  initializeViewServices(injector, query);

  const table = new WorkPackageTable(
    injector,
    dom.wrapper,
    dom.scroll,
    dom.tbody,
    dom.timelineBody,
    {} as WorkPackageTimelineTableController,
    new WorkPackageTableConfiguration(
      { ...(options.productionDefaults ? unbuildableColumns : harnessConfiguration), ...options.configuration },
    ),
  );

  const outputs:WorkPackageViewOutputs = {
    itemClicked: new EventEmitter<{ workPackageId:string, double:boolean }>(),
    stateLinkClicked: new EventEmitter<{ workPackageId:string, requestedState:string }>(),
  };
  new TableHandlerRegistry(injector).attachTo({ workPackageTable: table, ...outputs });

  let fixtures = options.workPackages;
  let destroyed = false;

  const nextRender = () => firstValueFrom(
    querySpace.tableRendered.values$().pipe(skip(querySpace.tableRendered.hasValue() ? 1 : 0), take(1)),
  );

  return {
    table,
    tbody: dom.tbody,
    container: dom.container,
    injector,
    querySpace,
    selection: injector.get(WorkPackageViewSelectionService),
    focus: injector.get(WorkPackageViewFocusService),
    outputs,

    render(workPackages = fixtures) {
      fixtures = workPackages;
      const resources = workPackages.map(buildWorkPackage);
      resources.forEach((wp) => {
        [...wp.getAncestors(), wp].forEach((resource) => states.workPackages.get(resource.id!).putValue(resource));
      });

      const rendered = nextRender();
      querySpace.results.putValue({ elements: resources } as WorkPackageCollectionResource);
      querySpace.initialized.putValue(null);

      return rendered;
    },

    nextRender,

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

    groupHeaderOf(row) {
      return locatePredecessorBySelector(row, `.${rowGroupClassName}`) as HTMLTableRowElement|null;
    },

    groupHeader(index) {
      const header = dom.tbody.querySelector<HTMLTableRowElement>(`tr.${rowGroupClassName}[data-group-index="${index}"]`);
      if (!header) {
        throw new Error(`No rendered group header ${index}`);
      }
      return header;
    },

    rowIds() {
      return this.rows().map((row) => row.dataset.workPackageId!);
    },

    renderedState() {
      return (querySpace.tableRendered.value ?? [])
        .filter(({ workPackageId }) => workPackageId !== null)
        .map(({ workPackageId, hidden }):[string, boolean] => [workPackageId!, hidden]);
    },

    click(workPackageId, init = {}) {
      const row = this.row(workPackageId);
      const target = row.querySelector('td') ?? row;
      fireEvent.click(target, init);
    },

    dragStart(workPackageId) {
      dragService.memberOf(dom.tbody).onDragStarted?.(this.row(workPackageId));
    },

    drop(sourceId, targetId, edge) {
      return new Promise((resolve) => {
        dragService.memberOf(dom.tbody).onMoved({ sourceId, targetId, edge }, resolve);
      });
    },

    addRelationRow(workPackageId, afterId) {
      const row = this.row(workPackageId).cloneNode(true) as HTMLTableRowElement;
      row.dataset.classIdentifier = `wp-relation-row-${afterId}-to-${workPackageId}`;
      this.row(afterId).after(row);
      const rendered = [...table.renderedRows];
      const index = rendered.findIndex((entry) => entry.classIdentifier === this.row(afterId).dataset.classIdentifier);
      rendered.splice(index + 1, 0, { classIdentifier: row.dataset.classIdentifier, workPackageId, hidden: false });
      querySpace.tableRendered.putValue(rendered);
      return row;
    },

    // The table redraws in a requestAnimationFrame followed by a setTimeout;
    // wait those out so a pending redraw cannot fire into a destroyed injector.
    async destroy() {
      if (destroyed) {
        return;
      }
      destroyed = true;
      await nextFrame();
      await nextTask();
      querySpace.stopAllSubscriptions.next();
      dom.wrapper.remove();
      injector.destroy();
    },
  };
}

class FakeDragAndDropService {
  private readonly members = new Map<HTMLElement, DragMember>();

  register(member:DragMember):void {
    this.members.set(member.dragContainer, member);
  }

  remove(container:HTMLElement):void {
    this.members.delete(container);
  }

  memberOf(container:HTMLElement):DragMember {
    const member = this.members.get(container);
    if (!member) {
      throw new Error('No drag member registered for the table body');
    }
    return member;
  }
}

/** Stands in for the Angular editing portal: a plain input the edit handler can focus. */
class FakeEditingPortalService {
  create(container:HTMLElement):Promise<EditFieldHandler> {
    const input = document.createElement('input');
    container.appendChild(input);
    return Promise.resolve({
      $onUserActivate: new Subject<void>(),
      focus: () => input.focus(),
      deactivate: () => input.remove(),
    } as unknown as EditFieldHandler);
  }
}

function harnessProviders(dragService:FakeDragAndDropService, options:TableHarnessOptions) {
  const editable = !!options.editing;
  const formWritable = options.editing?.formWritable ?? true;
  const subjectSchema = (writable:boolean) => ({ type: 'String', name: 'subject', writable });

  return [
    { provide: States, useValue: options.states ?? new States() },
    IsolatedQuerySpace,
    ActionsService,
    WorkPackageViewSelectionService,
    WorkPackageViewSelectionGesturesService,
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
      useFactory: (states:States) => ({
        work_packages: {
          cache: { current: (_id:string, fallback:unknown) => fallback },
          id: (id:string) => ({
            get: () => of(states.workPackages.get(id).value),
            requireAndStream: () => of(states.workPackages.get(id).value),
          }),
        },
      }),
      deps: [States],
    },
    {
      provide: SchemaCacheService,
      useValue: {
        of: () => ({
          ofProperty: (attribute:string) => (attribute === 'subject' ? subjectSchema(editable) : undefined),
          mappedName: (attribute:string) => attribute,
          isAttributeEditable: (attribute:string) => editable && attribute === 'subject',
        }),
      },
    },
    { provide: I18nService, useValue: { t: (key:string) => key, locale: 'en' } },
    { provide: HalResourceService, useValue: {} },
    {
      provide: HalResourceEditingService,
      useValue: {
        typedState: () => ({ hasValue: () => false, value: undefined }),
        stopEditing: () => undefined,
        changeFor: () => ({
          schema: { ofProperty: (attribute:string) => (attribute === 'subject' ? subjectSchema(formWritable) : null) },
          getForm: () => Promise.resolve(),
          reset: () => undefined,
        }),
      },
    },
    { provide: WorkPackageRelationsService, useValue: { state: () => ({ hasValue: () => false, value: undefined }) } },
    { provide: WorkPackageContextMenuHelperService, useValue: { getPermittedActions: () => [] } },
    { provide: OPContextMenuService, useValue: { close: () => undefined, show: () => undefined } },
    { provide: BannersService, useValue: { eeShowBanners: false } },
    { provide: PathHelperService, useValue: { genericWorkPackagePath: () => '/work_packages/1' } },
    { provide: CausedUpdatesService, useValue: { add: () => undefined } },
    { provide: StateService, useValue: { current: { name: 'work-packages.partitioned.list' }, href: () => '' } },
    { provide: UrlParamsService, useValue: { currentDetailsRouteParams: () => null, basePathWithoutDetails: () => '' } },
    { provide: KeepTabService, useValue: { currentDetailsTab: 'overview', currentShowTab: 'activity' } },
    { provide: FocusHelperService, useValue: { focus: () => undefined } },
    { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false } },
    { provide: HalResourceNotificationService, useValue: { handleRawError: () => undefined, showEditingBlockedError: () => undefined } },
    { provide: EditingPortalService, useValue: new FakeEditingPortalService() },
    { provide: CopyToClipboardService, useValue: {} },
    { provide: CurrentProjectService, useValue: { id: null, identifier: null } },
    { provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: new Subject<string>() } },
    { provide: DragAndDropService, useValue: dragService },
    {
      provide: TableDragActionsRegistryService,
      useFactory: (querySpace:IsolatedQuerySpace, injector:Injector) => ({
        get: () => Object.assign(new TableDragActionService(querySpace, injector), options.dragAction ?? {}),
      }),
      deps: [IsolatedQuerySpace, Injector],
    },
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

function buildQuery(columns:string[], groupBy:string|null, showHierarchies:boolean):QueryResource {
  return {
    id: null,
    columns: columns.map((id) => ({ id, name: id, _type: 'QueryColumn', href: `/api/v3/queries/columns/${id}` })),
    sortBy: [],
    groupBy: groupBy ? { id: groupBy, name: groupBy, href: `/api/v3/queries/group_bys/${groupBy}` } : null,
    showHierarchies,
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
