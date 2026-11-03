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
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { InlineCreateRowBuilder } from 'core-app/features/work-packages/components/wp-inline-create/inline-create-row-builder';
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
import { activeFieldClassName, activeFieldContainerClassName, EditForm } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { HalResourceEditFieldHandler } from 'core-app/shared/components/fields/edit/field-handler/hal-resource-edit-field-handler';
import { IntegerDisplayField } from 'core-app/shared/components/fields/display/field-types/integer-display-field.module';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { onDestroySafely } from 'core-app/shared/helpers/angular/owned-ui-cleanup';
import { internalContextMenuColumn, internalSortColumn } from '../builders/internal-sort-columns';
import { isNavigableColumn, navigableCellClassName } from '../handlers/state/keyboard/roving-tabindex';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

/** A relation column: `relationType` builds an `ofType` column, `children: true` the child relations column. */
export type RelationColumnSpec = { id:string, relationType:string }|{ id:string, children:true };

/** A plain column whose header renders without a sort link. */
export interface NonSortableColumnSpec { id:string, sortable:false }

export interface TableHarnessOptions {
  pagination?:{ offset:number; pageSize:number; total:number };
  /** Self link of the results collection; defaults to the global work packages collection. */
  collectionHref?:string;
  workPackages:WorkPackageFixture[];
  providers?:Provider[];
  /** Retains the root so a replacement table can mount with a fresh injector. */
  dom?:ReturnType<typeof buildDom>;
  /** Column ids, or relation column specs that render real relation rows once expanded. */
  columns?:(string|RelationColumnSpec|NonSortableColumnSpec)[];
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
  /** Renders the production `thead` and totals row around the results, for navigation that walks them. */
  productionMarkup?:boolean;
  /** Overrides for the drag action service the drop handler resolves. */
  dragAction?:Partial<TableDragActionService>;
  /** Uses the production action registry, including group and hierarchy actions. */
  builtinDragActions?:boolean;
  query?:QueryResource;
  onDropComplete?:(success:boolean) => void;
  /**
   * Makes `fields` (default `subject`) inline-editable; `formWritable: false` has the loaded form refuse them.
   * `save` stands in for the changeset save; without it every submit is an unchanged one.
   */
  editing?:{ formWritable?:boolean; fields?:string[]; save?:() => Promise<{ resource:WorkPackageResource; wasNew:boolean }> };
  requireDoubleClickForInlineEdit?:boolean;
  /** The application-wide resource cache; pass one instance to tables that share a page. */
  states?:States;
  /** Shows the timeline side through the query, as a saved Gantt view does. */
  timelineVisible?:boolean;
  requireAll?:(ids:string[]) => Promise<WorkPackageResource[]>;
  loadPositions?:() => Promise<QueryOrder>;
  /** Activates the baseline view service, so rows read their fixtures' `baseline` state. */
  baseline?:boolean;
  /** Whole translated strings by key, with `%{name}` interpolation; unlisted keys translate to themselves. */
  translations?:Record<string, string>;
  /** Runs against the fresh injector before the handler registry attaches, to seed state a predecessor view left behind; resolving a view service here constructs it ahead of the transformers, as production does. */
  beforeAttach?:(injector:Injector) => void;
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
  /** Asserts the `aria-rowindex` of every table row in document order and the table's `aria-rowcount`; requires `productionMarkup`. */
  expectRowPositions(indices:string[], count:string):void;
  /** Asserts that neither the table nor any of its rows carries a position. */
  expectNoRowPositions():void;
  /** The primary row of a work package, never one of its relation rows. */
  row(workPackageId:string):HTMLTableRowElement;
  /** The relation row of `to` under `from`, located by its occurrence key. */
  relationRow(from:string, to:string, type?:string):HTMLTableRowElement;
  /** The `thead` row; requires `productionMarkup`. */
  headerRow():HTMLTableRowElement;
  /** The header cells in column order, ending with the configuration cell; requires `productionMarkup`. */
  headerCells():HTMLTableCellElement[];
  /** The totals row; requires `productionMarkup`. */
  totalsRow():HTMLTableRowElement;
  timelineRow(workPackageId:string):HTMLElement;
  /** The timeline cell at the position of the given table row; both sides render one element per row. */
  timelineRowOf(row:HTMLElement):HTMLElement;
  groupHeaderOf(row:HTMLElement):HTMLTableRowElement|null;
  /** Fresh lookup; group headers are replaced on every collapse toggle. */
  groupHeader(index:number):HTMLTableRowElement;
  /** Selects the given columns as the column configuration does, redrawing the table without reloading results. */
  setColumns(columnIds:string[]):void;
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
  /** Appends the unsaved row the inline-create component renders into its own `<tbody>`. */
  addInlineCreateRow():HTMLTableRowElement;
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

const sumsSchemaHref = '/api/v3/work_packages/schemas/sums';

export function buildTable(options:TableHarnessOptions):TableHarness {
  const dragService = new FakeDragAndDropService();
  const injector = createEnvironmentInjector([...harnessProviders(dragService, options), ...(options.providers ?? [])], TestBed.inject(EnvironmentInjector));
  injector.get(DisplayFieldService)
    .addFieldType(TextDisplayField, 'text', ['String'])
    .addFieldType(IntegerDisplayField, 'integer', ['Integer']);
  const querySpace = injector.get(IsolatedQuerySpace);
  const states = injector.get(States);
  const dom = options.dom ?? buildDom({ productionMarkup: options.productionMarkup });

  const groupBy = options.groupBy ?? 'status';
  const query = options.query ?? buildQuery(
    options.columns ?? ['id', 'subject'],
    options.groups ? groupBy : null,
    options.showHierarchies ?? false,
    options.timelineVisible ?? false,
    options.highlightingMode,
  );
  querySpace.query.putValue(query);
  const configuration = new WorkPackageTableConfiguration(
    { ...(options.productionDefaults ? unbuildableColumns : harnessConfiguration), ...options.configuration },
  );
  if (options.productionMarkup) {
    fillProductionMarkup(dom.wrapper, query, configuration);
  }
  querySpace.groups.putValue((options.groups ?? []).map((group, index) => buildGroup(group, groupBy, index)));
  initializeViewServices(injector, query);

  const table = new WorkPackageTable(
    injector,
    dom.wrapper,
    dom.scroll,
    dom.tbody,
    dom.timelineBody,
    {} as WorkPackageTimelineTableController,
    configuration,
  );

  const outputs:WorkPackageViewOutputs = {
    itemClicked: new EventEmitter<{ workPackageId:string, double:boolean }>(),
    stateLinkClicked: new EventEmitter<{ workPackageId:string, requestedState:string }>(),
  };
  options.beforeAttach?.(injector);
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
      querySpace.results.putValue({
        elements: resources,
        groups: querySpace.groups.value ?? [],
        href: options.collectionHref ?? '/api/v3/work_packages',
        count: resources.length,
        total: options.pagination?.total ?? resources.length,
        pageSize: options.pagination?.pageSize ?? Math.max(resources.length, 1),
        offset: options.pagination?.offset ?? 1,
        sumsSchema: { href: sumsSchemaHref },
      } as WorkPackageCollectionResource);
      querySpace.initialized.putValue(null);

      return rendered;
    },

    nextRender,

    rows() {
      return Array.from(dom.tbody.querySelectorAll<HTMLTableRowElement>('tr.wp-table--row'));
    },

    expectRowPositions(indices, count) {
      const element = dom.tbody.closest('table')!;
      expect(Array.from(element.rows).map((row) => row.getAttribute('aria-rowindex'))).toEqual(indices);
      expect(element).toHaveAttribute('aria-rowcount', count);
    },

    expectNoRowPositions() {
      const element = dom.tbody.closest('table')!;
      expect(element).not.toHaveAttribute('aria-rowcount');
      Array.from(element.rows).forEach((row) => expect(row).not.toHaveAttribute('aria-rowindex'));
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

    headerRow() {
      return productionMarkupElement<HTMLTableRowElement>(dom.wrapper, 'thead tr');
    },

    headerCells() {
      return Array.from(productionMarkupElement(dom.wrapper, 'thead tr').querySelectorAll<HTMLTableCellElement>('th'));
    },

    totalsRow() {
      return productionMarkupElement<HTMLTableRowElement>(dom.wrapper, '.work-package-table > tbody:not(.work-package--results-tbody) > tr.wp-table--sums-row');
    },

    timelineRow(workPackageId) {
      const row = dom.timelineBody.querySelector<HTMLElement>(`.wp-timeline-cell[data-work-package-id="${workPackageId}"]`);
      if (!row) {
        throw new Error(`No rendered timeline row for work package ${workPackageId}`);
      }
      return row;
    },

    timelineRowOf(row) {
      const cell = dom.timelineBody.children.item(Array.from(dom.tbody.children).indexOf(row));
      if (!(cell instanceof HTMLElement)) {
        throw new Error('No rendered timeline row at the position of the given table row');
      }
      return cell;
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

    setColumns(columnIds) {
      injector.get(WorkPackageViewColumnsService).setColumns(columnIds.map((id) => buildColumn(id) as QueryColumn));
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

    addInlineCreateRow() {
      const workPackage = buildWorkPackage({ id: HAL_NEW_RESOURCE_ID, subject: '' });
      states.workPackages.get(HAL_NEW_RESOURCE_ID).putValue(workPackage);
      const builder = new InlineCreateRowBuilder(injector, table);
      table.editing.startEditing(workPackage, builder.classIdentifier(workPackage));
      const [row] = builder.buildEmpty(workPackage);
      inlineCreateBodyOf(dom).append(row);
      return row;
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

/** Stands in for the Angular editing portal: a plain input, labeled with its field and error messages like the portal, driven by the production field handler. */
class FakeEditingPortalService {
  create(container:HTMLElement, injector:Injector, form:EditForm, schema:IFieldSchema, fieldName:string, errors:string[], destroyRef?:DestroyRef):Promise<EditFieldHandler> {
    const wrapper = document.createElement('div');
    wrapper.className = activeFieldContainerClassName;
    const label = document.createElement('label');
    label.className = 'sr-only';
    const input = document.createElement('input');
    input.className = activeFieldClassName;
    wrapper.append(label, input);
    container.appendChild(wrapper);
    const handler = new HalResourceEditFieldHandler(injector, form, fieldName, schema, container, injector.get(PathHelperService), errors, destroyRef);
    input.id = handler.htmlId;
    label.htmlFor = handler.htmlId;
    const markErrors = () => {
      wrapper.classList.toggle('-error', handler.isErrorenous);
      label.textContent = `${handler.fieldLabel} ${handler.errorMessageOnLabel()}`.trim();
    };
    markErrors();
    handler.errorsChanged$.subscribe(markErrors);
    let unregister:() => void = () => undefined;
    handler.onDestroy.pipe(take(1)).subscribe(() => {
      wrapper.remove();
      unregister();
    });
    if (destroyRef) unregister = onDestroySafely(destroyRef, () => handler.deactivate(false));
    return Promise.resolve(handler);
  }
}

export function harnessProviders(dragService:FakeDragAndDropService, options:TableHarnessOptions) {
  const editable = !!options.editing;
  const formWritable = options.editing?.formWritable ?? true;
  const editableFields = options.editing?.fields ?? ['subject'];
  const fieldSchema = (name:string, writable:boolean) => (editableFields.includes(name) ? { type: 'String', name, writable } : undefined);
  const sumsSchema = buildSumsSchema(options.groups ?? []);

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
          cache: {
            current: (_id:string, fallback:unknown) => fallback,
            state: (id:string) => states.workPackages.get(id),
          },
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
        state: () => ({ value: sumsSchema }),
        of: () => ({
          ofProperty: (attribute:string) => fieldSchema(attribute, editable),
          mappedName: (attribute:string) => attribute,
          availableAttributes: ['subject'],
          isAttributeEditable: (attribute:string) => editable && editableFields.includes(attribute),
        }),
      },
    },
    { provide: I18nService, useValue: { t: translate(options.translations), locale: 'en' } },
    { provide: HalResourceService, useValue: {} },
    {
      provide: HalResourceEditingService,
      useValue: {
        typedState: () => ({ hasValue: () => false, value: undefined }),
        stopEditing: () => undefined,
        save: options.editing?.save,
        changeFor: () => ({
          schema: { ofProperty: (attribute:string) => fieldSchema(attribute, formWritable) ?? null },
          getForm: () => Promise.resolve(),
          reset: () => undefined,
          isEmpty: () => !options.editing?.save,
        }),
      },
    },
    { provide: WorkPackageRelationsService, useValue: relationsStub(options.relations ?? []) },
    { provide: WorkPackageContextMenuHelperService, useValue: { getPermittedActions: () => [] } },
    { provide: OPContextMenuService, useValue: { close: () => undefined, show: () => undefined } },
    {
      provide: ConfigurationService,
      useValue: { requireDoubleClickForInlineEdit: () => !!options.requireDoubleClickForInlineEdit },
    },
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
    { provide: WorkPackageViewBaselineService, useValue: baselineStub(!!options.baseline) },
    { provide: HalResourceNotificationService, useValue: { handleRawError: () => undefined, showEditingBlockedError: () => undefined, showSave: () => undefined } },
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

function translate(translations:Record<string, string> = {}) {
  return (key:string, args:Record<string, unknown> = {}) => (translations[key] ?? key)
    .replace(/%\{(\w+)\}/g, (match, name:string) => (Object.hasOwn(args, name) ? String(args[name]) : match));
}

function baselineStub(active:boolean) {
  return {
    isActive: () => active,
    isChanged: (workPackage:WorkPackageResource, attribute:string) => active
      && Object.hasOwn(workPackage.attributesByTimestamp?.[0] ?? {}, attribute),
  };
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

function productionMarkupElement<T extends HTMLElement = HTMLElement>(wrapper:HTMLElement, selector:string):T {
  const element = wrapper.querySelector<T>(selector);
  if (!element) {
    throw new Error(`No ${selector} rendered; build the table with productionMarkup`);
  }
  return element;
}

function fillProductionMarkup(wrapper:HTMLElement, query:QueryResource, configuration:WorkPackageTableConfiguration) {
  const keyboardNavigationEnabled = configuration.keyboardNavigationEnabled;
  const tabindex = keyboardNavigationEnabled ? ' tabindex="-1"' : '';
  const navigable = keyboardNavigationEnabled ? ' wp-table--navigable-cell' : '';
  const columns = query.columns as unknown as { id:string, name:string, sortable?:boolean }[];
  const headerCells = columns.map(({ id, name, sortable }) => `
    <th class="wp-table--table-header${navigable}">
      <div class="generic-table--sort-header-outer">
        <span class="generic-table--sort-header">${sortable === false ? `<a${tabindex}>${name}</a>` : `<a href="#" id="${id}"${tabindex}>${name}</a>`}</span>
      </div>
    </th>`).join('');
  const configurationCell = `
    <th class="wp-table--configuration-modal--trigger wp-table--context-menu-th${navigable}">
      <button type="button" class="wp-table--columns-selection"${tabindex}></button>
    </th>`;

  productionMarkupElement(wrapper, 'thead tr').innerHTML = headerCells + configurationCell;
  const augmentedColumns = [
    ...(configuration.dragAndDropEnabled ? [internalSortColumn] : []),
    ...(columns as QueryColumn[]),
    internalContextMenuColumn,
  ];
  productionMarkupElement(wrapper, 'tr.wp-table--sums-row').innerHTML = augmentedColumns
    .map((column) => `<td${keyboardNavigationEnabled && isNavigableColumn(column, configuration) ? ` class="${navigableCellClassName}"` : ''}></td>`)
    .join('');
}

function inlineCreateBodyOf(dom:ReturnType<typeof buildDom>):HTMLTableSectionElement {
  const table = dom.tbody.closest('table')!;
  const existing = table.querySelector<HTMLTableSectionElement>('tbody[wpInlineCreate]');
  if (existing) {
    return existing;
  }

  const body = document.createElement('tbody');
  body.setAttribute('wpInlineCreate', '');
  const totalsBody = table.querySelector(':scope > tbody:has(> tr.wp-table--sums-row)');
  (totalsBody ?? dom.tbody).after(body);
  return body;
}

export function buildDom(options:{ productionMarkup?:boolean } = {}) {
  const wrapper = document.createElement('div');
  wrapper.innerHTML = `
    <div class="work-packages-tabletimeline--table-side work-package-table--container">
      <table class="work-package-table">
        ${options.productionMarkup ? '<thead class="-sticky"><tr></tr></thead>' : ''}
        <tbody class="work-package--results-tbody"></tbody>
        ${options.productionMarkup ? '<tbody><tr class="wp-table--sums-row wp-table--row"></tr></tbody>' : ''}
        ${options.productionMarkup ? '<tbody wpInlineCreate><tr><td><button type="button" class="spot-link">Create new work package</button></td></tr></tbody>' : ''}
      </table>
    </div>
    <div class="work-packages-tabletimeline--timeline-side"><div class="wp-table-timeline--body"></div></div>
  `;
  document.body.appendChild(wrapper);

  return {
    wrapper,
    container: wrapper.querySelector<HTMLElement>('.work-packages-tabletimeline--table-side')!,
    scroll: wrapper.querySelector<HTMLElement>('.work-package-table--container')!,
    tbody: wrapper.querySelector<HTMLTableSectionElement>('tbody.work-package--results-tbody')!,
    timelineBody: wrapper.querySelector<HTMLElement>('.wp-table-timeline--body')!,
  };
}

function buildSumsSchema(groups:GroupFixture[]):Record<string, IFieldSchema> {
  const attributes = groups.flatMap((group) => Object.keys(group.sums ?? {}));

  return Object.fromEntries(attributes.map((name) => [name, { type: 'Integer', name, writable: false, hasDefault: false }]));
}

export function buildQuery(columns:(string|RelationColumnSpec|NonSortableColumnSpec)[], groupBy:string|null, showHierarchies:boolean, timelineVisible:boolean, highlightingMode:HighlightingMode = 'inline'):QueryResource {
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

function buildColumn(column:string|RelationColumnSpec|NonSortableColumnSpec) {
  if (typeof column === 'string') {
    return { id: column, name: column, _type: 'QueryColumn', href: `/api/v3/queries/columns/${column}` };
  }

  const { id } = column;
  const href = `/api/v3/queries/columns/${id}`;
  if ('sortable' in column) {
    return { id, name: id, _type: 'QueryColumn', href, sortable: false };
  }

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
