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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { fireEvent } from '@testing-library/dom';
import {
  createEnvironmentInjector, DestroyRef, EnvironmentInjector, EventEmitter, Injector, Provider, Type,
} from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom, of, Subject } from 'rxjs';
import { skip, take } from 'rxjs/operators';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
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
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
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
import { OpTableActionsService } from 'core-app/features/work-packages/components/wp-table/table-actions/table-actions.service';
import { OpContextMenuTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/context-menu-table-action';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { DragAndDropService, DragMember } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import type { Edge } from 'core-common/drag-and-drop/reorder';
import { rowGroupClassName } from '../builders/modes/grouped/grouped-classes.constants';
import { TableHandlerRegistry } from '../handlers/table-handler-registry';
import { locatePredecessorBySelector } from '../helpers/wp-table-row-helpers';
import { WorkPackageTable } from '../wp-fast-table';
import {
  buildGroup, buildRelations, buildWorkPackage, GroupFixture, RelationFixture, WorkPackageFixture,
} from './work-package-fixture';
import { queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { HighlightingMode } from '../builders/highlighting/highlighting-mode.const';
import { EditingPortalService } from 'core-app/shared/components/fields/edit/editing-portal/editing-portal-service';
import { EditFieldHandler } from 'core-app/shared/components/fields/edit/editing-portal/edit-field-handler';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';

/** A relation column: `relationType` builds an `ofType` column, `children: true` the child relations column. */
export type RelationColumnSpec = { id:string, relationType:string }|{ id:string, children:true };

export interface TableHarnessOptions {
  workPackages:WorkPackageFixture[];
  providers?:Provider[];
  /** Retains the root so a replacement table can mount with a fresh injector. */
  dom?:ReturnType<typeof buildDom>;
  /** Column ids, or relation column specs that render real relation rows once expanded. */
  columns?:(string|RelationColumnSpec)[];
  /** Feeds the relations service, so `ofType` columns find these relations between fixtures. */
  relations?:RelationFixture[];
  /** Loads fixture `children` into the resource cache on render (default); `false` leaves them for `requireAll`. */
  loadChildren?:boolean;
  /** The query's highlighting mode; defaults to `inline`, which skips the row highlighting pass. */
  highlightingMode?:HighlightingMode;
  /** Renders the table grouped by `groupBy` (default `status`) with one header row per group. */
  groups?:GroupFixture[];
  groupBy?:string;
  showHierarchies?:boolean;
  configuration?:WorkPackageTableConfigurationObject;
  /** Keeps production defaults for every setting but the extra columns the harness cannot build. */
  productionDefaults?:boolean;
  /** Overrides for the drag action service the drop handler resolves. */
  dragAction?:Partial<TableDragActionService>;
  /** Uses the production action registry, including group and hierarchy actions. */
  builtinDragActions?:boolean;
  query?:QueryResource;
  onDropComplete?:(success:boolean) => void;
  /** Makes `subject` inline-editable; `formWritable: false` has the loaded form refuse the field. */
  editing?:{ formWritable?:boolean };
  /** The application-wide resource cache; pass one instance to tables that share a page. */
  states?:States;
  /** Shows the timeline side through the query, as a saved Gantt view does. */
  timelineVisible?:boolean;
  requireAll?:(ids:string[]) => Promise<WorkPackageResource[]>;
  loadPositions?:() => Promise<QueryOrder>;
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
  /** Every rendered work-package row, relation rows included. */
  rows():HTMLTableRowElement[];
  /** The primary row of a work package, never one of its relation rows. */
  row(workPackageId:string):HTMLTableRowElement;
  /** The relation row of `to` under `from`, located by its occurrence key. */
  relationRow(from:string, to:string, type?:string):HTMLTableRowElement;
  timelineRow(workPackageId:string):HTMLElement;
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
  /** Expands the relation column of a work package; works before the first render. */
  expand(workPackageId:string, columnId:string):void;
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
  const injector = createEnvironmentInjector([...harnessProviders(dragService, options), ...(options.providers ?? [])], TestBed.inject(EnvironmentInjector));
  injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
  const querySpace = injector.get(IsolatedQuerySpace);
  const states = injector.get(States);
  const dom = options.dom ?? buildDom();

  const groupBy = options.groupBy ?? 'status';
  const query = options.query ?? buildQuery(
    options.columns ?? ['id', 'subject'],
    options.groups ? groupBy : null,
    options.showHierarchies ?? false,
    options.timelineVisible ?? false,
    options.highlightingMode,
  );
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
      if (options.loadChildren !== false) {
        workPackages.flatMap((fixture) => fixture.children ?? []).map(buildWorkPackage)
          .forEach((child) => states.workPackages.get(child.id!).putValue(child));
      }

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
      const row = dom.tbody.querySelector<HTMLTableRowElement>(`tr.wp-table--row:not(.wp-table--relations-additional-row)[data-work-package-id="${workPackageId}"]`);
      if (!row) {
        throw new Error(`No rendered row for work package ${workPackageId}`);
      }
      return row;
    },

    relationRow(from, to, type = 'ofType') {
      const row = dom.tbody.querySelector<HTMLTableRowElement>(`tr[data-occurrence-key="relation:${type}:${from}:${to}"]`);
      if (!row) {
        throw new Error(`No rendered ${type} relation row from ${from} to ${to}`);
      }
      return row;
    },

    timelineRow(workPackageId) {
      const row = dom.timelineBody.querySelector<HTMLElement>(`.wp-timeline-cell[data-work-package-id="${workPackageId}"]`);
      if (!row) {
        throw new Error(`No rendered timeline row for work package ${workPackageId}`);
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
        dragService.memberOf(dom.tbody).onMoved({ sourceId, targetId, edge }, (success) => {
          options.onDropComplete?.(success);
          resolve(success);
        });
      });
    },

    expand(workPackageId, columnId) {
      injector.get(WorkPackageViewRelationColumnsService).setExpandFor(workPackageId, columnId);
    },

    destroy() {
      if (destroyed) {
        return Promise.resolve();
      }
      destroyed = true;
      table.destroy();
      dom.wrapper.remove();
      injector.destroy();
      return Promise.resolve();
    },
  };
}

export class FakeDragAndDropService {
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
  create(container:HTMLElement, _injector:Injector, form:EditForm, _schema:IFieldSchema, fieldName:string, _errors:string[], destroyRef?:DestroyRef):Promise<EditFieldHandler> {
    const input = document.createElement('input');
    input.className = 'inline-edit--field';
    container.appendChild(input);
    const onDestroy = new Subject<void>();
    let unregister:() => void = () => undefined;
    const handler = {
      onDestroy,
      $onUserActivate: new Subject<void>(),
      focus: () => input.focus(),
      deactivate: () => {
        input.remove();
        delete form.activeFields[fieldName];
        onDestroy.next();
        onDestroy.complete();
        unregister();
        form.reset(fieldName);
      },
    } as unknown as EditFieldHandler;
    if (destroyRef) unregister = onDestroySafely(destroyRef, () => handler.deactivate(false));
    return Promise.resolve(handler);
  }
}

export function harnessProviders(dragService:FakeDragAndDropService, options:TableHarnessOptions) {
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
    { provide: WorkPackagesListService, useValue: {} },
    {
      provide: ApiV3Service,
      useFactory: (states:States) => ({
        work_packages: {
          requireAll: options.requireAll ?? ((ids:string[]) => Promise.resolve(
            ids.map((id) => states.workPackages.get(id).value!).filter(Boolean),
          )),
          cache: { current: (_id:string, fallback:unknown) => fallback },
          id: (id:string) => ({
            get: () => of(states.workPackages.get(id).value),
            requireAndStream: () => of(states.workPackages.get(id).value),
          }),
        },
        queries: { id: () => ({ order: { get: options.loadPositions ?? (() => Promise.resolve({})) } }) },
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
    { provide: WorkPackageRelationsService, useValue: relationsStub(options.relations ?? []) },
    { provide: WorkPackageContextMenuHelperService, useValue: { getPermittedActions: () => [] } },
    { provide: OPContextMenuService, useValue: { close: () => undefined, show: () => undefined } },
    {
      provide: OpTableActionsService,
      useFactory: () => {
        const actions = new OpTableActionsService();
        actions.setActions((injector, workPackage) => new OpContextMenuTableAction(injector, workPackage));
        return actions;
      },
    },
    { provide: BannersService, useValue: { eeShowBanners: false } },
    { provide: PathHelperService, useValue: { genericWorkPackagePath: () => '/work_packages/1' } },
    { provide: CausedUpdatesService, useValue: { add: () => undefined } },
    { provide: UrlParamsService, useValue: { currentDetailsRouteParams: () => null, basePathWithoutDetails: () => '' } },
    { provide: KeepTabService, useValue: { currentDetailsTab: 'overview', currentShowTab: 'activity' } },
    { provide: FocusHelperService, useValue: { focus: () => undefined } },
    { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false } },
    { provide: HalResourceNotificationService, useValue: { handleRawError: () => undefined, showEditingBlockedError: () => undefined } },
    { provide: WorkPackageNotificationService, useExisting: HalResourceNotificationService },
    { provide: EditingPortalService, useValue: new FakeEditingPortalService() },
    { provide: CopyToClipboardService, useValue: {} },
    { provide: CurrentProjectService, useValue: { id: null, identifier: null } },
    { provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: new Subject<string>() } },
    { provide: DragAndDropService, useValue: dragService },
    {
      provide: TableDragActionsRegistryService,
      useFactory: (querySpace:IsolatedQuerySpace, injector:Injector) => ({
        get: () => options.builtinDragActions
          ? new TableDragActionsRegistryService().get(injector)
          : Object.assign(new TableDragActionService(querySpace, injector), options.dragAction ?? {}),
      }),
      deps: [IsolatedQuerySpace, Injector],
    },
  ];
}

function relationsStub(relations:RelationFixture[]) {
  const byWorkPackage = buildRelations(relations);
  return {
    state: (workPackageId:string) => {
      const value = byWorkPackage.get(workPackageId);
      return { hasValue: () => value !== undefined, value };
    },
  };
}

export function buildDom() {
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

export function buildQuery(columns:(string|RelationColumnSpec)[], groupBy:string|null, showHierarchies:boolean, timelineVisible:boolean, highlightingMode:HighlightingMode = 'inline'):QueryResource {
  return {
    id: null,
    columns: columns.map(buildColumn),
    sortBy: [],
    groupBy: groupBy ? { id: groupBy, name: groupBy, href: `/api/v3/queries/group_bys/${groupBy}` } : null,
    showHierarchies,
    highlightingMode,
    highlightedAttributes: [],
    timelineVisible,
    timelineZoomLevel: 'days',
    timelineLabels: undefined,
  } as unknown as QueryResource;
}

function buildColumn(column:string|RelationColumnSpec) {
  if (typeof column === 'string') {
    return { id: column, name: column, _type: 'QueryColumn', href: `/api/v3/queries/columns/${column}` };
  }

  const { id } = column;
  const href = `/api/v3/queries/columns/${id}`;
  return 'children' in column
    ? { id, name: id, _type: queryColumnTypes.RELATION_CHILD, href }
    : { id, name: id, _type: queryColumnTypes.RELATION_OF_TYPE, relationType: column.relationType, href };
}

export function initializeViewServices(injector:Injector, query:QueryResource) {
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
