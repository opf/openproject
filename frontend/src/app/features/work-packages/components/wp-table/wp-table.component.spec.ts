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

import { headerRowKey, inlineCreateRowKey } from 'core-app/features/work-packages/components/wp-fast-table/row-keys';
import type { PaintScope } from 'core-app/features/work-packages/components/wp-fast-table/row-mutations';
import { Component, Injector, NO_ERRORS_SCHEMA, signal } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { BehaviorSubject, config, of, Subject } from 'rxjs';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { States } from 'core-app/core/states/states.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { URN_UNDISCLOSED } from 'core-app/core/apiv3/api-v3-urns';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC, QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageInlineCreateComponent } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.component';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { editModeClassName } from 'core-app/shared/components/fields/edit/edit-field.component';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { IntegerDisplayField } from 'core-app/shared/components/fields/display/field-types/integer-display-field.module';
import { LinkDisplayField } from 'core-app/shared/components/fields/display/field-types/link-display-field.module';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { HighlightedResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/highlighted-resource-display-field.module';
import { ResourceDisplayField } from 'core-app/shared/components/fields/display/field-types/resource-display-field.module';
import { TypeDisplayField } from 'core-app/shared/components/fields/display/field-types/type-display-field.module';
import { WorkPackageIdDisplayField } from 'core-app/shared/components/fields/display/field-types/wp-id-display-field.module';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import {
  buildColumn, buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices,
} from '../wp-fast-table/testing/table-harness';
import { buildGroup, buildWorkPackage, WorkPackageFixture } from '../wp-fast-table/testing/work-package-fixture';
import { WorkPackageTimelineTableController } from './timeline/container/wp-timeline-container.directive';
import { WorkPackagesTableComponent } from './wp-table.component';
import { WorkPackageTableRowComponent } from '../wp-fast-table/template-rows/wp-table-row.component';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpActionMenuService } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.service';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';

/** Shows the table or the card view, as `wp-list-view` does when the viewport or query changes. */
@Component({
  template: '@if (showTable()) { <wp-table [configuration]="configuration" /> }',
  standalone: false,
})
class ListViewStandInComponent {
  showTable = signal(true);

  configuration:Record<string, boolean|string> = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    contextMenuEnabled: false,
    inlineCreateEnabled: false,
    dragAndDropEnabled: false,
  };
}

describe('WorkPackagesTableComponent lifecycle', () => {
  let fixture:ComponentFixture<ListViewStandInComponent>;
  let querySpace:IsolatedQuerySpace;
  let states:States;
  let timeline:WorkPackageViewTimelineService;
  let actions:ActionsService;
  let unhandled:unknown[];
  let previousHandler:typeof config.onUnhandledError;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [WorkPackagesTableComponent, ListViewStandInComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false, live$: () => of(null) } },
      ],
    }).compileComponents();

    const injector = TestBed.inject(Injector);
    injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
    injector.get(DisplayFieldService).addFieldType(IntegerDisplayField, 'integer', ['Integer']);
    querySpace = TestBed.inject(IsolatedQuerySpace);
    states = TestBed.inject(States);
    timeline = TestBed.inject(WorkPackageViewTimelineService);
    actions = TestBed.inject(ActionsService);

    const query = buildQuery(['id', 'subject'], null, false, false);
    querySpace.query.putValue(query);
    querySpace.groups.putValue([]);
    initializeViewServices(injector, query);
    TestBed.inject(WorkPackageViewSumService).initialize(query);
    putResults([]);

    fixture = TestBed.createComponent(ListViewStandInComponent);
    document.body.appendChild(fixture.nativeElement as HTMLElement);
    fixture.detectChanges();

    unhandled = [];
    previousHandler = config.onUnhandledError;
    config.onUnhandledError = (error) => unhandled.push(error);
  });

  afterEach(() => {
    config.onUnhandledError = previousHandler;
    (fixture.nativeElement as HTMLElement).remove();
  });

  function putResults(fixtures:WorkPackageFixture[]) {
    const resources = fixtures.map(buildWorkPackage);
    resources.forEach((wp) => states.workPackages.get(wp.id!).putValue(wp));
    querySpace.results.putValue({ elements: resources, count: resources.length, total: resources.length } as unknown as WorkPackageCollectionResource);
  }

  /** Feeds a reloaded result set the way `WpStatesInitializationService.updateQuerySpace` does. */
  function reload(fixtures:WorkPackageFixture[]) {
    querySpace.tableRendered.clear();
    putResults(fixtures);
    querySpace.initialized.putValue(null);
  }

  function renderedIds():string[] {
    return (querySpace.tableRendered.value ?? [])
      .filter(({ workPackageId }) => workPackageId !== null)
      .map(({ workPackageId }) => workPackageId!);
  }

  // A table registered after `initialized` already has a value replays that
  // value and queues a stale render first, so wait for the requested one.
  async function render(fixtures:WorkPackageFixture[]) {
    reload(fixtures);
    await waitFor(() => expect(renderedIds()).toEqual(fixtures.map(({ id }) => id)));
  }

  /** Shows the table and registers the fast table as the timeline container directive would. */
  async function showTable(fixtures:WorkPackageFixture[]):Promise<HTMLElement> {
    fixture.componentInstance.showTable.set(true);
    fixture.detectChanges();
    const debug = fixture.debugElement.query(By.directive(WorkPackagesTableComponent));
    const element = debug.nativeElement as HTMLElement;
    const timelineBody = document.createElement('div');
    element.querySelector('.work-packages-tabletimeline--timeline-side')!.appendChild(timelineBody);
    (debug.componentInstance as WorkPackagesTableComponent)
      .registerTimeline({} as WorkPackageTimelineTableController, timelineBody);
    await render(fixtures);
    return element;
  }

  function showCards() {
    fixture.componentInstance.showTable.set(false);
    fixture.detectChanges();
  }

  /** The card view writes the rendered occurrences into the same query space state as the table. */
  function cardsRendered(ids:string[]) {
    querySpace.tableRendered.putValue(ids.map((id) => ({ classIdentifier: `wp-card-${id}`, workPackageId: id, hidden: false })));
  }

  function rowIds(element:HTMLElement):string[] {
    return Array.from(element.querySelectorAll<HTMLTableRowElement>('tr.wp-table--row[data-work-package-id]'))
      .map((row) => row.dataset.workPackageId!);
  }

  function countRefreshRequests():() => number {
    let count = 0;
    actions.ofType(tableRefreshRequest).subscribe(() => { count += 1; });
    return () => count;
  }

  async function settle() {
    await nextFrame();
    await nextTask();
  }

  it('stops reacting to the query space once the table is replaced by cards', async () => {
    const table = await showTable([{ id: '1' }, { id: '2' }]);
    showCards();

    timeline.setVisible(true);
    reload([{ id: '3' }]);
    await settle();

    expect(unhandled).toEqual([]);
    expect(querySpace.tableRendered.hasValue()).toBe(false);
    expect(rowIds(table)).toEqual(['1', '2']);
  });

  it('keeps a table shown again after cards reacting to the timeline', async () => {
    await showTable([{ id: '1' }]);
    showCards();
    const table = await showTable([{ id: '3' }]);

    timeline.setVisible(true);
    await settle();

    expect(unhandled).toEqual([]);
    expect(rowIds(table)).toEqual(['3']);
    expect(table.querySelector('.work-packages-tabletimeline--table-side')).toHaveClass('-timeline-visible');
    expect(table.querySelector('.work-packages-tabletimeline--timeline-side')).toHaveClass('-timeline-visible');
  });

  it('stays clean across repeated table and card transitions', async () => {
    await showTable([{ id: '1' }]);
    showCards();
    await showTable([{ id: '2' }]);
    showCards();

    timeline.setVisible(true);
    reload([{ id: '4' }]);
    await settle();

    expect(unhandled).toEqual([]);
    expect(querySpace.tableRendered.hasValue()).toBe(false);
  });

  it('refreshes once per sharing update, only through the live table', async () => {
    const refreshes = countRefreshRequests();
    await showTable([{ id: '1' }]);
    showCards();
    cardsRendered(['1']);

    actions.dispatch(shareModalUpdated({ workPackageId: '1' }));
    expect(refreshes()).toBe(0);

    await showTable([{ id: '1' }]);
    actions.dispatch(shareModalUpdated({ workPackageId: '1' }));
    expect(refreshes()).toBe(1);
  });
  it('preserves card entries when the removed table has queued a render', async () => {
    await showTable([{ id: '1' }]);
    reload([{ id: '2' }]);
    showCards();
    cardsRendered(['2']);
    await settle();
    expect(unhandled).toEqual([]);
    expect(querySpace.tableRendered.value).toEqual([
      { classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false },
    ]);
  });

  it('can be destroyed before timeline registration and ignores a late registration', () => {
    const component = fixture.debugElement.query(By.directive(WorkPackagesTableComponent))
      .componentInstance as WorkPackagesTableComponent;
    expect(() => fixture.destroy()).not.toThrow();
    const controller = {} as WorkPackageTimelineTableController;
    expect(() => component.registerTimeline(controller, document.createElement('div'))).not.toThrow();
    expect(component.workPackageTable).toBeUndefined();
    expect(controller.workPackageTable).toBeUndefined();
  });

  it('destroys the previous table before replacing its timeline registration', async () => {
    await showTable([{ id: '1' }]);
    const component = fixture.debugElement.query(By.directive(WorkPackagesTableComponent))
      .componentInstance as WorkPackagesTableComponent;
    const previous = component.workPackageTable;
    component.registerTimeline({} as WorkPackageTimelineTableController, document.createElement('div'));
    expect(previous.destroyed).toBe(true);
    expect(component.workPackageTable.destroyed).toBe(false);
    await settle();
  });

  it('enables, disables and re-enables scrolling through timeline visibility', async () => {
    const element = await showTable([{ id: '1' }]);
    const tableSide = element.querySelector<HTMLElement>('.work-packages-tabletimeline--table-side')!;
    const timelineSide = element.querySelector<HTMLElement>('.work-packages-tabletimeline--timeline-side')!;
    for (const side of [tableSide, timelineSide]) {
      side.style.cssText = 'display: block; height: 40px; overflow: auto';
      const filler = document.createElement('div');
      filler.style.height = '1000px';
      side.appendChild(filler);
    }
    timeline.setVisible(true);
    tableSide.scrollTop = 30;
    fireEvent.scroll(tableSide);
    // Firefox snaps scroll offsets to device pixels, so a requested offset can land a fraction short.
    expect(timelineSide.scrollTop).toBeCloseTo(30, 0);
    timeline.setVisible(false);
    timelineSide.scrollTop = 60;
    fireEvent.scroll(timelineSide);
    expect(tableSide.scrollTop).toBeCloseTo(30, 0);
    timeline.setVisible(true);
    timelineSide.scrollTop = 90;
    fireEvent.scroll(timelineSide);
    expect(tableSide.scrollTop).toBeCloseTo(90, 0);
  });

});

describe('WorkPackagesTableComponent physical columns', () => {
  const queryColumns = 2;
  let mounted:HTMLElement|undefined;

  afterEach(() => {
    mounted?.remove();
    mounted = undefined;
  });

  async function mount(configuration:Record<string, boolean>, baseline:boolean) {
    await TestBed.configureTestingModule({
      declarations: [WorkPackagesTableComponent, ListViewStandInComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => baseline, isChanged: () => false, live$: () => of(null) } },
      ],
    }).compileComponents();

    const injector = TestBed.inject(Injector);
    injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
    injector.get(DisplayFieldService).addFieldType(IntegerDisplayField, 'integer', ['Integer']);
    const querySpace = TestBed.inject(IsolatedQuerySpace);
    const states = TestBed.inject(States);
    const query = buildQuery(['id', 'subject'], null, false, false);
    querySpace.query.putValue(query);
    querySpace.groups.putValue([]);
    initializeViewServices(injector, query);
    TestBed.inject(WorkPackageViewSumService).initialize(query);
    querySpace.results.putValue({ elements: [], count: 0, total: 0 } as unknown as WorkPackageCollectionResource);

    const fixture = TestBed.createComponent(ListViewStandInComponent);
    fixture.componentInstance.configuration = { ...fixture.componentInstance.configuration, ...configuration };
    mounted = fixture.nativeElement as HTMLElement;
    document.body.appendChild(mounted);
    fixture.detectChanges();

    const debug = fixture.debugElement.query(By.directive(WorkPackagesTableComponent));
    const element = debug.nativeElement as HTMLElement;
    const timelineBody = document.createElement('div');
    element.querySelector('.work-packages-tabletimeline--timeline-side')!.appendChild(timelineBody);
    (debug.componentInstance as WorkPackagesTableComponent)
      .registerTimeline({} as WorkPackageTimelineTableController, timelineBody);

    const resources = [buildWorkPackage({ id: '1' }), buildWorkPackage({ id: '2' })];
    resources.forEach((wp) => states.workPackages.get(wp.id!).putValue(wp));
    querySpace.results.putValue({ elements: resources, count: resources.length, total: resources.length } as unknown as WorkPackageCollectionResource);
    querySpace.initialized.putValue(null);
    await waitFor(() => expect(element.querySelectorAll('tr.wp-table--row[data-work-package-id]')).toHaveLength(2));

    return { fixture, element, component: debug.componentInstance as WorkPackagesTableComponent };
  }

  const spannedColumns = (row:HTMLTableRowElement) => Array.from(row.cells)
    .reduce((total, cell) => total + cell.colSpan, 0);

  describe.each([true, false])('with drag and drop %s', (drag) => {
    describe.each([true, false])('and baseline %s', (baseline) => {
      it.each([true, false])('renders the same columns in header, colgroup and rows with a trailing column %s', async (trailing) => {
        const { element, component } = await mount({
          dragAndDropEnabled: drag,
          actionsColumnEnabled: trailing,
        }, baseline);
        const expected = queryColumns + Number(drag) + Number(baseline) + Number(trailing);

        expect(element.querySelectorAll('thead th')).toHaveLength(expected);
        expect(element.querySelectorAll('colgroup col')).toHaveLength(expected);
        element.querySelectorAll<HTMLTableRowElement>('tr.wp-table--row[data-work-package-id]')
          .forEach((row) => expect(spannedColumns(row)).toBe(expected));
        expect(component.numTableColumns).toBe(expected);
        expect(component.workPackageTable.colspan).toBe(expected);
      });
    });
  });
});

@Component({
  template: '<input type="text" aria-label="Work package to reference">',
  standalone: true,
})
class ReferenceStandInComponent {}

@Component({
  template: '@for (configuration of configurations; track $index) { <wp-table [configuration]="configuration" /> }',
  standalone: false,
})
class TwoTablesStandInComponent {
  configurations = [{ ...new ListViewStandInComponent().configuration }, { ...new ListViewStandInComponent().configuration }];
}

describe('WorkPackagesTableComponent treegrid structure', () => {
  const newStatus = { value: 'New', href: '/api/v3/statuses/1', count: 1, sums: { storyPoints: 13 } };
  const inProgressStatus = { value: 'In progress', href: '/api/v3/statuses/2', count: 1, sums: { storyPoints: 21 } };
  const translations = {
    'js.label_work_package_plural': 'Work packages',
    'js.label_sorting': 'Sorting',
    'js.toolbar.settings.configure_view': 'Configure view',
    'js.work_packages.table.grid_actions_header': 'Actions',
    'js.work_packages.table.grid_baseline_header': 'Comparison status',
    'js.work_packages.table.sorted_by': 'Sorted by %{criteria}.',
    'js.work_packages.table.sort_criterion_ascending': '%{column} ascending',
    'js.work_packages.table.sort_criterion_descending': '%{column} descending',
    'js.work_packages.table.sorted_manually': 'Sorted manually.',
    'js.inplace.errors.messages_on_field': 'This field is invalid: %{messages}',
    'js.button_cancel': 'Cancel',
    'js.button_edit': 'Edit',
    'js.label_open_context_menu': 'Open context menu',
  };
  let baselineActive:boolean;
  let canAdd:BehaviorSubject<boolean>;
  let canReference:BehaviorSubject<boolean>;
  let created:Subject<WorkPackageResource>;
  let newWorkPackage:WorkPackageResource;
  let querySpace:IsolatedQuerySpace;
  let states:States;
  let fixture:ComponentFixture<ListViewStandInComponent|TwoTablesStandInComponent>;

  beforeEach(async () => {
    baselineActive = false;
    canAdd = new BehaviorSubject(true);
    canReference = new BehaviorSubject(false);
    created = new Subject();
    newWorkPackage = Object.assign(buildWorkPackage({ id: HAL_NEW_RESOURCE_ID, subject: '' }), { __initialized_at: 1 });
    await TestBed.configureTestingModule({
      imports: [WorkPackageTableRowComponent],
      declarations: [WorkPackagesTableComponent, WorkPackageInlineCreateComponent, ListViewStandInComponent, TwoTablesStandInComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), {
          workPackages: [],
          groups: [newStatus, inProgressStatus],
          relations: [
            { from: '1', to: '3', type: 'follows', reverseType: 'precedes' },
            { from: '2', to: '3', type: 'follows', reverseType: 'precedes' },
          ],
          translations,
          editing: { fields: ['subject', 'project', 'customField1'] },
        }),
        provideHttpClient(),
        { provide: HalResourceService, useClass: HalResourceService },
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => baselineActive, isChanged: () => false, live$: () => of(null) } },
        {
          provide: WorkPackageInlineCreateService,
          useValue: {
            canAdd,
            canReference,
            buttonTexts: { create: 'Create new work package', reference: 'Reference an existing work package' },
            referenceComponentClass: ReferenceStandInComponent,
            newInlineWorkPackageCreated: new Subject<string>(),
          },
        },
        {
          provide: WorkPackageCreateService,
          useValue: {
            onNewWorkPackage: () => created,
            cancelCreation: () => undefined,
            createOrContinueWorkPackage: () => Promise.resolve({
              projectedResource: newWorkPackage,
              state: { values$: () => of({ schema: {} }) },
            }),
          },
        },
        { provide: AuthorisationService, useValue: {} },
        { provide: WorkPackagesListService, useValue: { conditionallyLoadForm: () => Promise.resolve() } },
      ],
    }).compileComponents();

    const injector = TestBed.inject(Injector);
    injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
    injector.get(DisplayFieldService).addFieldType(IntegerDisplayField, 'integer', ['Integer']);
    querySpace = TestBed.inject(IsolatedQuerySpace);
    states = TestBed.inject(States);
    states.workPackages.get(HAL_NEW_RESOURCE_ID).putValue(newWorkPackage);
    const query = buildQuery(['id', 'subject'], null, false, false);
    querySpace.query.putValue(query);
    querySpace.groups.putValue([]);
    initializeViewServices(injector, query);
    TestBed.inject(WorkPackageViewSumService).initialize(query);
    putResults([]);

    const editing = TestBed.inject(HalResourceEditingService);
    const changeFor = editing.changeFor.bind(editing);
    vi.spyOn(editing, 'changeFor').mockImplementation((resource) => ({
      ...changeFor(resource),
      getForm: () => Promise.resolve({ validationErrors: { subject: {} } }),
    }) as unknown as ReturnType<typeof changeFor>);
  });

  afterEach(() => {
    (fixture?.nativeElement as HTMLElement|undefined)?.remove();
  });

  function putResults(fixtures:WorkPackageFixture[]) {
    const resources = fixtures.map(buildWorkPackage);
    resources.forEach((wp) => states.workPackages.get(wp.id!).putValue(wp));
    querySpace.results.putValue({
      elements: resources,
      offset: 1,
      pageSize: 20,
      count: resources.length,
      total: resources.length,
      sumsSchema: { href: '/api/v3/work_packages/schemas/sums' },
    } as unknown as WorkPackageCollectionResource);
  }

  function tables():WorkPackagesTableComponent[] {
    return fixture.debugElement.queryAll(By.directive(WorkPackagesTableComponent))
      .map((debug) => debug.componentInstance as WorkPackagesTableComponent);
  }

  function registerTables() {
    fixture.debugElement.queryAll(By.directive(WorkPackagesTableComponent)).forEach((debug) => {
      const component = debug.componentInstance as WorkPackagesTableComponent;
      if (component.workPackageTable) return;
      const timelineBody = document.createElement('div');
      (debug.nativeElement as HTMLElement).querySelector('.work-packages-tabletimeline--timeline-side')!.appendChild(timelineBody);
      component.registerTimeline({} as WorkPackageTimelineTableController, timelineBody);
    });
  }

  async function render(fixtures:WorkPackageFixture[]) {
    querySpace.tableRendered.clear();
    putResults(fixtures);
    querySpace.initialized.putValue(null);
    await waitFor(() => expect(querySpace.tableRendered.value?.filter(({ workPackageId }) => workPackageId !== null))
      .toHaveLength(fixtures.length));
  }

  async function mount(configuration:Record<string, boolean|string>, fixtures:WorkPackageFixture[] = [{ id: '1' }, { id: '2' }]) {
    const listView = TestBed.createComponent(ListViewStandInComponent);
    fixture = listView;
    listView.componentInstance.configuration = { ...listView.componentInstance.configuration, ...configuration };
    document.body.appendChild(listView.nativeElement as HTMLElement);
    listView.detectChanges();
    registerTables();
    await render(fixtures);
    return tables()[0];
  }

  function sortBy(...criteria:[string, string][]) {
    TestBed.inject(WorkPackageViewSortByService).update(criteria.map(([column, direction]) => ({
      column: { id: column, name: column, href: `/api/v3/queries/columns/${column}` },
      direction: { href: direction },
    }) as unknown as QuerySortByResource));
  }

  function headerRow():HTMLElement {
    return screen.getByRole('treegrid').querySelector('thead tr')!;
  }

  function referencedIds(root:ParentNode):string[] {
    return Array.from(root.querySelectorAll('[aria-describedby], [aria-labelledby]'))
      .flatMap((element) => [element.getAttribute('aria-describedby'), element.getAttribute('aria-labelledby')])
      .flatMap((value) => value?.split(/\s+/) ?? []);
  }

  describe('naming', () => {
    it('names the table', async () => {
      await mount({});
      const grid = screen.getByRole('treegrid', { name: 'Work packages' });

      expect(grid).toHaveAttribute('aria-multiselectable', 'true');
    });

    it('takes the name from the referenced heading instead of aria-label', async () => {
      await mount({ labelledBy: 'heading' });
      const grid = screen.getByRole('treegrid');

      expect(grid).toHaveAttribute('aria-labelledby', 'heading');
      expect(grid).not.toHaveAttribute('aria-label');
    });
  });

  it('paints the column header row through a table mutation', async () => {
    const component = await mount({});
    const scopes:PaintScope[] = [];
    vi.spyOn(component.workPackageTable.keyboardNavigation, 'rowsChanged').mockImplementation(({ scope }) => { scopes.push(scope); });

    sortBy(['subject', QUERY_SORT_BY_DESC]);

    expect(scopes).toContainEqual(new Set([headerRowKey]));
    expect(headerRow().querySelector('[aria-sort="descending"]')).not.toBeNull();
  });

  it('repaints positions after Angular updates the header', async () => {
    const component = await mount({});
    const painted:string[] = [];
    vi.spyOn(component.workPackageTable.painter, 'paint').mockImplementation(() => {
      painted.push(headerRow().getAttribute('aria-label') ?? headerRow().textContent ?? '');
      expect(headerRow().querySelector('[aria-sort="descending"]')).not.toBeNull();
      return { positionsWithdrawn: null };
    });

    sortBy(['subject', QUERY_SORT_BY_DESC]);

    expect(painted).not.toHaveLength(0);
  });

  describe('header structure', () => {
    it('exposes a level 1 header row inside a rowgroup', async () => {
      await mount({});

      expect(headerRow().parentElement).toHaveAttribute('role', 'rowgroup');
      expect(headerRow()).toHaveAttribute('role', 'row');
      expect(headerRow()).toHaveAttribute('aria-level', '1');
      expect(headerRow()).not.toHaveAttribute('aria-selected');
      expect(headerRow()).not.toHaveAttribute('aria-expanded');
    });

    it('paints the column header role on every header cell', async () => {
      baselineActive = true;
      await mount({ dragAndDropEnabled: true, actionsColumnEnabled: true });
      const cells = Array.from((headerRow() as HTMLTableRowElement).cells);

      expect(cells.map((cell) => cell.getAttribute('role'))).toEqual(cells.map(() => 'columnheader'));
    });

    it('names the drag, baseline, query and actions column headers', async () => {
      baselineActive = true;
      await mount({ dragAndDropEnabled: true, actionsColumnEnabled: true });
      const headers = within(headerRow()).getAllByRole('columnheader');

      expect(headers).toHaveLength(5);
      ['Sorting', 'Comparison status', 'id', 'subject', 'Actions'].forEach((name, index) => {
        expect(headers[index]).toHaveAccessibleName(name);
      });
    });

    it('gives the actions header text instead of a label when it holds no configuration control', async () => {
      await mount({ actionsColumnEnabled: true });
      const actions = within(headerRow()).getAllByRole('columnheader').at(-1)!;

      expect(actions).toHaveAccessibleName('Actions');
      expect(actions).toHaveTextContent('Actions');
      expect(actions).not.toHaveAttribute('aria-label');
    });

    it('names the trailing header after the configuration control', async () => {
      await mount({ columnMenuEnabled: true });

      expect(within(headerRow()).getAllByRole('columnheader').at(-1)).toHaveAccessibleName('Configure view');
    });

    it('draws the focus ring of the header row on its sticky cells', async () => {
      await mount({});
      const shadows = () => within(headerRow()).getAllByRole('columnheader').map((header) => getComputedStyle(header).boxShadow);

      expect(shadows().every((shadow) => shadow === 'none')).toBe(true);

      headerRow().focus();

      expect(shadows().every((shadow) => shadow.includes('inset'))).toBe(true);
      expect(shadows()[0]).toContain(' 2px 0px 0px 0px inset');
      expect(shadows().at(-1)).toContain(' -2px 0px 0px 0px inset');

      headerRow().closest('table')!.setAttribute('dir', 'rtl');

      expect(shadows()[0]).toContain(' -2px 0px 0px 0px inset');
      expect(shadows().at(-1)).toContain(' 2px 0px 0px 0px inset');
    });
  });

  describe('sorting', () => {
    function sortStates():(string|null)[] {
      return within(headerRow()).getAllByRole('columnheader').map((header) => header.getAttribute('aria-sort'));
    }

    it('marks only the primary criterion and describes all criteria in order', async () => {
      await mount({});

      sortBy(['subject', QUERY_SORT_BY_ASC], ['id', QUERY_SORT_BY_DESC]);
      expect(sortStates()).toEqual([null, 'ascending']);
      expect(screen.getByRole('treegrid')).toHaveAccessibleDescription('Sorted by subject ascending and id descending.');

      sortBy(['id', QUERY_SORT_BY_DESC], ['subject', QUERY_SORT_BY_ASC]);
      expect(sortStates()).toEqual(['descending', null]);
      expect(screen.getByRole('treegrid')).toHaveAccessibleDescription('Sorted by id descending and subject ascending.');
    });

    it('describes a primary criterion whose column is not displayed', async () => {
      await mount({});

      sortBy(['status', QUERY_SORT_BY_ASC], ['id', QUERY_SORT_BY_ASC], ['subject', QUERY_SORT_BY_DESC]);

      expect(sortStates()).toEqual([null, null]);
      expect(screen.getByRole('treegrid'))
        .toHaveAccessibleDescription('Sorted by status ascending, id ascending, and subject descending.');
    });

    it('describes manual sorting', async () => {
      await mount({});

      sortBy(['manualSorting', QUERY_SORT_BY_ASC]);

      expect(sortStates()).toEqual([null, null]);
      expect(screen.getByRole('treegrid')).toHaveAccessibleDescription('Sorted manually.');
    });
  });

  describe('instances', () => {

    it('gives each table a unique id once its table is registered', async () => {
      fixture = TestBed.createComponent(TwoTablesStandInComponent);
      document.body.appendChild(fixture.nativeElement as HTMLElement);
      expect(() => fixture.detectChanges()).not.toThrow();
      registerTables();
      await render([{ id: '1' }]);

      const ids = Array.from(document.querySelectorAll('table.work-package-table')).map((table) => table.id);
      expect(ids).toHaveLength(2);
      ids.forEach((id) => expect(id).toMatch(/^wp-table-/));
      expect(ids[0]).not.toEqual(ids[1]);
    });

    it('gives two tables on one page their own references', async () => {
      fixture = TestBed.createComponent(TwoTablesStandInComponent);
      document.body.appendChild(fixture.nativeElement as HTMLElement);
      fixture.detectChanges();
      registerTables();
      await render([{ id: '1' }]);
      sortBy(['subject', QUERY_SORT_BY_ASC]);

      const grids = screen.getAllByRole('treegrid');
      expect(grids).toHaveLength(2);
      await waitFor(() => grids.forEach((grid) => {
        expect(grid.querySelectorAll('tr.wp-table--row[data-work-package-id="1"]')).toHaveLength(1);
      }));
      grids.forEach((grid) => expect(grid).toHaveAccessibleDescription('Sorted by subject ascending.'));
      expect(grids[0].getAttribute('aria-describedby')).not.toEqual(grids[1].getAttribute('aria-describedby'));

      const references = referencedIds(document);
      expect(references).not.toHaveLength(0);
      references.forEach((id) => expect(document.querySelectorAll(`[id="${id}"]`)).toHaveLength(1));
    });
  });

  describe('empty results', () => {
    const emptySection = () => document.querySelector<HTMLTableSectionElement>('tbody.work-package--empty-tbody');
    const resultsSection = () => document.querySelector<HTMLTableSectionElement>('tbody.work-package--results-tbody')!;

    function expectEmpty() {
      const row = within(emptySection()!).getByRole('row');

      expect(emptySection()).toHaveAttribute('role', 'rowgroup');
      expect(emptySection()).not.toHaveAttribute('aria-hidden');
      expect(row).toHaveAttribute('aria-level', '1');
      expect(row).not.toHaveAttribute('aria-selected');
      expect(row).not.toHaveAttribute('aria-expanded');
      expect(within(row).getByRole('gridcell')).toHaveAttribute('colspan', '2');
      expect(resultsSection()).toHaveAttribute('aria-hidden', 'true');
    }

    function expectPopulated() {
      expect(emptySection()).not.toBeInTheDocument();
      expect(resultsSection()).toHaveAttribute('role', 'rowgroup');
      expect(resultsSection()).not.toHaveAttribute('aria-hidden');
    }

    it('exposes the message row and hides the results section until results return', async () => {
      await mount({}, []);
      expectEmpty();

      await render([{ id: '1' }]);
      expectPopulated();
      expect(within(resultsSection()).getByRole('row')).toHaveAttribute('aria-level', '1');

      await render([]);
      expectEmpty();

      await render([{ id: '1' }]);
      expectPopulated();
      expect(within(resultsSection()).getByRole('row')).toHaveAttribute('aria-level', '1');
    });
  });

  describe('inline create', () => {
    const inlineCreate = { inlineCreateEnabled: true, actionsColumnEnabled: true };
    const createSection = () => document.querySelector<HTMLTableSectionElement>('tbody[wpInlineCreate]')!;
    const createRow = () => createSection().querySelector<HTMLTableRowElement>('.wp-inline-create-row');

    function expectStructuralRow(row:HTMLElement) {
      expect(row).toHaveAttribute('role', 'row');
      expect(row).toHaveAttribute('aria-level', '1');
      expect(row).not.toHaveAttribute('aria-selected');
      expect(row).not.toHaveAttribute('aria-expanded');
      expect(Array.from((row as HTMLTableRowElement).cells).map((cell) => cell.getAttribute('role')))
        .toEqual(Array.from((row as HTMLTableRowElement).cells).map(() => 'gridcell'));
    }

    function expectExposed() {
      expect(createSection()).toHaveAttribute('role', 'rowgroup');
      expect(createSection()).not.toHaveAttribute('aria-hidden');
    }

    async function openCreateRow():Promise<HTMLTableRowElement> {
      fireEvent.click(within(createSection()).getByText('Create new work package'));
      await waitFor(() => {
        expect(createRow()).toBeInTheDocument();
        expect(createSection().querySelector('.wp-inline-create-button-row')).not.toBeInTheDocument();
        expect(within(createRow()!).getByRole('textbox')).toBeInTheDocument();
      });
      return createRow()!;
    }

    it('exposes the Create and reference buttons in a structural row', async () => {
      canReference.next(true);
      await mount(inlineCreate);
      const row = within(createSection()).getByRole('row');

      expectExposed();
      expectStructuralRow(row);
      expect(within(row).getAllByRole('button')).toHaveLength(2);
    });

    it('opens and closes the create row through table mutations', async () => {
      const component = await mount(inlineCreate);
      const scopes:PaintScope[] = [];
      vi.spyOn(component.workPackageTable.keyboardNavigation, 'rowsChanged').mockImplementation(({ scope }) => { scopes.push(scope); });

      const row = await openCreateRow();
      expect(scopes.at(-1)).toEqual(new Set([inlineCreateRowKey]));
      expect(createSection()).not.toHaveAttribute('aria-hidden');

      scopes.length = 0;
      fireEvent.keyDown(within(row).getByRole('textbox'), { key: 'Escape' });
      await waitFor(() => expect(scopes).toContainEqual(new Set([inlineCreateRowKey])));
    });

    it('repaints positions after permission and reference template changes', async () => {
      canReference.next(true);
      const component = await mount(inlineCreate);
      const { painter } = component.workPackageTable;
      const paint = painter.paint.bind(painter);
      const painted = vi.spyOn(painter, 'paint');
      painted.mockImplementation((scope) => {
        const result = paint(scope);
        expect(createSection()).not.toHaveAttribute('aria-hidden');
        return result;
      });

      fireEvent.click(within(createSection()).getByText('Reference an existing work package'));
      expect(painted).toHaveBeenCalled();
      expect(within(createSection()).getByRole('textbox', { name: 'Work package to reference' })).toBeInTheDocument();
      const exposure:(string|null)[] = [];
      painted.mockImplementation((scope) => {
        const result = paint(scope);
        exposure.push(createSection().getAttribute('aria-hidden'));
        return result;
      });
      canAdd.next(false);
      canReference.next(false);
      expect(exposure).toEqual([null, 'true']);
    });

    it('updates absolute positions through create and permission changes', async () => {
      const component = await mount(inlineCreate);
      const table = component.workPackageTable.tbody.closest('table')!;
      expect(table).toHaveAttribute('aria-rowcount', '4');
      expect(within(createSection()).getByRole('row')).toHaveAttribute('aria-rowindex', '4');

      const row = await openCreateRow();
      expect(table).toHaveAttribute('aria-rowcount', '4');
      expect(row).toHaveAttribute('aria-rowindex', '4');
      const editor = within(row).getByRole('textbox');
      editor.focus();
      component.workPackageTable.painter.paint('positions');
      expect(document.activeElement).toBe(editor);

      fireEvent.keyDown(editor, { key: 'Escape' });
      await waitFor(() => expectExposed());
      expect(within(createSection()).getByRole('row')).toHaveAttribute('aria-rowindex', '4');
      canAdd.next(false);
      expect(table).toHaveAttribute('aria-rowcount', '3');
      expect(createSection()).toHaveAttribute('aria-hidden', 'true');
    });

    it('withdraws positions while the button row and the editing row coexist', async () => {
      const component = await mount(inlineCreate);
      const table = component.workPackageTable.tbody.closest('table')!;
      const { painter } = component.workPackageTable;
      const paint = painter.paint.bind(painter);
      const counts:(string|null)[] = [];
      vi.spyOn(painter, 'paint').mockImplementation((scope) => {
        const result = paint(scope);
        if (createSection().querySelectorAll('tr').length === 2) counts.push(table.getAttribute('aria-rowcount'));
        return result;
      });

      await openCreateRow();

      expect(counts).not.toHaveLength(0);
      expect(new Set(counts)).toEqual(new Set([null]));
    });

    it('stops repainting a removed table on permission changes', async () => {
      const component = await mount(inlineCreate);
      const painted = vi.spyOn(component.workPackageTable.painter, 'paint');
      const listView = fixture as ComponentFixture<ListViewStandInComponent>;
      listView.componentInstance.showTable.set(false);
      listView.detectChanges();
      painted.mockClear();

      canAdd.next(false);
      canReference.next(true);
      await nextTask();

      expect(painted).not.toHaveBeenCalled();
    });

    it('repaints positions after imperative create append and removal', async () => {
      const component = await mount(inlineCreate);
      const painted = vi.spyOn(component.workPackageTable.painter, 'paint');
      painted.mockImplementation(() => {
        expect(createRow()).toBeInTheDocument();
        return { positionsWithdrawn: null };
      });
      const row = await openCreateRow();
      expect(painted).toHaveBeenCalled();
      const editor = within(row).getByRole('textbox');
      editor.focus();
      const focused = document.activeElement;
      painted.mockRestore();
      component.workPackageTable.painter.paint('positions');
      expect(document.activeElement).toBe(focused);

      const { painter } = component.workPackageTable;
      const paint = painter.paint.bind(painter);
      const rowPresentOnPaint:boolean[] = [];
      const removing = vi.spyOn(painter, 'paint').mockImplementation((scope) => {
        rowPresentOnPaint.push(createRow() !== null);
        return paint(scope);
      });
      fireEvent.keyDown(editor, { key: 'Escape' });
      await waitFor(() => expect(createRow()).not.toBeInTheDocument());
      expect(rowPresentOnPaint).toContain(true);
      expect(rowPresentOnPaint.at(-1)).toBe(false);
      removing.mockRestore();
      await waitFor(() => expectExposed());
    });

    it('renders the active reference row with the same semantics', async () => {
      canReference.next(true);
      await mount(inlineCreate);

      fireEvent.click(within(createSection()).getByText('Reference an existing work package'));
      const reference = within(createSection()).getByRole('textbox', { name: 'Work package to reference' });

      expect(reference.closest('td')).toHaveAttribute('role', 'gridcell');
      expectStructuralRow(reference.closest('tr')!);
      expectExposed();
    });

    it('keeps a validation message native inside its gridcell', async () => {
      await mount(inlineCreate);
      const row = await openCreateRow();
      const form = tables()[0].workPackageTable.editing.forms[HAL_NEW_RESOURCE_ID];
      await waitFor(() => expect(form.activeFields.subject).toBeDefined());

      form.activeFields.subject.setErrors(["Subject can't be blank."]);

      const message = within(row).getByText(/Subject can't be blank\./);
      const editor = within(row).getByRole('textbox', { name: /This field is invalid: Subject can't be blank\./ });
      expect(message.closest('td')).toHaveAttribute('role', 'gridcell');
      expect(editor.closest('td')).toBe(message.closest('td'));
      [message, editor].forEach((element) => {
        expect(element).not.toHaveAttribute('role');
        expect(element).not.toHaveAttribute('aria-selected');
      });
      expectStructuralRow(row);
    });

    it('keeps the active create row and its editor structural, also after a refresh', async () => {
      await mount(inlineCreate);
      const row = await openCreateRow();

      expectExposed();
      expectStructuralRow(row);
      expect(within(row).getByRole('textbox').closest('td')).toHaveAttribute('role', 'gridcell');

      const idCell = row.cells[0];
      const columns = TestBed.inject(WorkPackageViewColumnsService);
      columns.update([...columns.getColumns()]);

      expect(createRow()).toBe(row);
      expect(row.cells[0]).not.toBe(idCell);
      expectStructuralRow(row);
    });

    it('keeps the Cancel link in a gridcell when no trailing column renders', async () => {
      await mount({ inlineCreateEnabled: true });
      const row = await openCreateRow();

      expect(within(row).getByRole('link', { name: 'Cancel' }).closest('td')).toHaveAttribute('role', 'gridcell');
      expectStructuralRow(row);
    });

    it('restores the button row after cancelling, hiding the section in between', async () => {
      await mount(inlineCreate);
      const row = await openCreateRow();

      fireEvent.keyDown(within(row).getByRole('textbox'), { key: 'Escape' });

      expect(createRow()).not.toBeInTheDocument();
      expect(createSection()).toHaveAttribute('aria-hidden', 'true');

      await waitFor(() => expectExposed());
      expectStructuralRow(within(createSection()).getByRole('row'));
    });

    it('hands a created work package to the results as a selectable row', async () => {
      await mount(inlineCreate);
      await openCreateRow();

      created.next(Object.assign(buildWorkPackage({ id: '3' }), { __initialized_at: 1 }));
      expect(createRow()).not.toBeInTheDocument();
      await render([{ id: '1' }, { id: '2' }, { id: '3' }]);

      const results = document.querySelector<HTMLTableSectionElement>('tbody.work-package--results-tbody')!;
      expect(results.querySelector('tr[data-work-package-id="3"]')).toHaveAttribute('aria-selected', 'true');
      await waitFor(() => expectStructuralRow(within(createSection()).getByRole('row')));
      expectExposed();
    });

    it('hides the section while neither permission renders a row', async () => {
      canAdd.next(false);
      await mount(inlineCreate);

      expect(createSection()).toHaveAttribute('role', 'rowgroup');
      expect(createSection()).toHaveAttribute('aria-hidden', 'true');
      expect(createSection().rows).toHaveLength(0);

      canAdd.next(true);
      expectExposed();
      expectStructuralRow(within(createSection()).getByRole('row'));

      canAdd.next(false);
      expect(createSection()).toHaveAttribute('aria-hidden', 'true');
    });
  });

  it('keeps imperative rows for tables with relation columns when the flag is off', async () => {
    vi.spyOn(TestBed.inject(WorkPackageViewColumnsService), 'getColumns').mockReturnValue(
      [buildColumn('id'), buildColumn('subject'), buildColumn({ id: 'relationsOfTypeFollows', relationType: 'follows' })] as QueryColumn[],
    );

    await mount({}, [{ id: '1' }]);

    expect(document.querySelector('.work-package--results-tbody > tr[data-work-package-id="1"]')).not.toHaveAttribute('opwptablerow');
  });

  it.each([false, true])('keeps native row headers when columns change (templates: %s)', async (templates) => {
    Object.assign(TestBed.inject(ConfigurationService), { activeFeatureFlags: templates ? ['newTableRendering'] : [] });
    const columns = TestBed.inject(WorkPackageViewColumnsService);
    columns.update([buildColumn('id')] as QueryColumn[]);
    await mount({}, [{ id: '42', subject: 'Header subject' }]);
    const row = () => document.querySelector<HTMLTableRowElement>('.work-package--results-tbody > tr')!;
    const idHeader = within(row()).getByRole('rowheader', { name: '42' });
    expect(idHeader.tagName).toBe('TH');
    expect(idHeader).toHaveAttribute('scope', 'row');

    columns.update([buildColumn('subject'), buildColumn('id')] as QueryColumn[]);
    await waitFor(() => expect(within(row()).getByRole('rowheader', { name: 'Header subject' })).toHaveAttribute('scope', 'row'));
    expect(row().querySelector('th.subject')).toBeTruthy();
    expect(row().querySelector('td.id')).toHaveTextContent('42');

    columns.update([buildColumn('id')] as QueryColumn[]);
    await waitFor(() => expect(within(row()).getByRole('rowheader', { name: '42' })).toHaveAttribute('scope', 'row'));
    expect(row().querySelector('.subject')).toBeNull();
  });

  describe('with the newTableRendering flag', () => {
    beforeEach(() => {
      Object.assign(TestBed.inject(ConfigurationService), { activeFeatureFlags: ['newTableRendering'] });
    });

    const resultRow = (id:string) => document.querySelector<HTMLTableRowElement>(`.work-package--results-tbody > tr[data-work-package-id="${id}"]`);

    it('renders the result rows from the row template, painted like legacy rows', async () => {
      await mount({}, [{ id: '1', subject: 'First' }, { id: '2', subject: 'Second' }]);

      const row = resultRow('1')!;
      expect(row).toHaveAttribute('opwptablerow');
      expect(row).toHaveAttribute('data-occurrence-key', 'wp:1');
      expect(row).toHaveClass('wp-table--row', 'wp-row-1', 'wp-row-1-table');
      expect(row).toHaveAttribute('aria-rowindex');
      expect(within(row).getByRole('rowheader', { name: 'First' })).toBeInTheDocument();
      expect(within(resultRow('2')!).getByRole('rowheader', { name: 'Second' })).toBeInTheDocument();
    });

    it('keeps the elements of rows that survive a redraw', async () => {
      await mount({}, [{ id: '1' }, { id: '2' }]);
      const first = resultRow('1');

      await render([{ id: '3' }, { id: '1' }]);

      expect(resultRow('1')).toBe(first);
      expect(resultRow('2')).toBeNull();
      expect(first?.previousElementSibling).toBe(resultRow('3'));
    });

    it('keeps template rows aligned with the timeline across redraws', async () => {
      const timeline = TestBed.inject(WorkPackageViewTimelineService);
      timeline.setVisible(true);
      await mount({}, [{ id: '1' }, { id: '2' }]);
      const first = resultRow('1');
      const timelineIdentifiers = () => Array.from(document.querySelectorAll<HTMLElement>('.wp-timeline-cell'))
        .map((row) => row.dataset.classIdentifier);

      expect(first).toHaveAttribute('opwptablerow');
      expect(timelineIdentifiers()).toEqual(['wp-row-1', 'wp-row-2']);

      await render([{ id: '3' }, { id: '1' }]);

      expect(resultRow('1')).toBe(first);
      expect(first?.previousElementSibling).toBe(resultRow('3'));
      expect(timelineIdentifiers()).toEqual(['wp-row-3', 'wp-row-1']);

      await render([]);
      expect(resultRow('1')).toBeNull();
      expect(timelineIdentifiers()).toEqual([]);
    });

    it('renders hierarchy occurrences in tree order with a stable ancestor row and collapse state', async () => {
      const parent = { id: '1' };
      const child = { id: '2', ancestors: [parent] };
      const hierarchies = TestBed.inject(WorkPackageViewHierarchiesService);
      hierarchies.setEnabled();
      states.workPackages.get('1').putValue(buildWorkPackage(parent));
      const listView = TestBed.createComponent(ListViewStandInComponent);
      fixture = listView;
      document.body.appendChild(listView.nativeElement as HTMLElement);
      listView.detectChanges();
      registerTables();
      querySpace.tableRendered.clear();
      putResults([child, { id: '3' }]);
      querySpace.initialized.putValue(null);
      await waitFor(() => expect(querySpace.tableRendered.value?.map(({ workPackageId }) => workPackageId)).toEqual(['1', '2', '3']));

      const ancestor = resultRow('1')!;
      expect(ancestor).toHaveAttribute('opwptablerow');
      expect(ancestor).toHaveAttribute('data-occurrence-key', 'ancestor:1');
      expect(ancestor).toHaveAttribute('aria-expanded', 'true');
      expect(resultRow('2')).toHaveAttribute('aria-level', '2');

      fireEvent.click(ancestor.querySelector('.wp-table--hierarchy-indicator')!);
      expect(ancestor).toHaveAttribute('aria-expanded', 'false');
      expect(resultRow('2')).not.toBeVisible();

      querySpace.tableRendered.clear();
      putResults([child, { id: '4' }]);
      querySpace.initialized.putValue(null);
      await waitFor(() => expect(querySpace.tableRendered.value?.map(({ workPackageId }) => workPackageId)).toEqual(['1', '2', '4']));
      expect(resultRow('1')).toBe(ancestor);
      expect(ancestor).toHaveAttribute('aria-expanded', 'false');
      expect(resultRow('2')).not.toBeVisible();

      fireEvent.click(ancestor.querySelector('.wp-table--hierarchy-indicator')!);
      expect(ancestor).toHaveAttribute('aria-expanded', 'true');
      expect(resultRow('2')).toBeVisible();
    });

    it('keeps template group headers and sums aligned with their collapsed rows', async () => {
      querySpace.groups.putValue([buildGroup(newStatus, 'status', 0), buildGroup(inProgressStatus, 'status', 1)]);
      TestBed.inject(WorkPackageViewColumnsService).update(buildQuery(['id', 'subject', 'storyPoints'], 'status', false, true).columns);
      TestBed.inject(WorkPackageViewTimelineService).setVisible(true);
      const entries = [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: inProgressStatus } },
      ];
      const { workPackageTable } = await mount({}, entries);
      const before = workPackageTable.templateRows!.snapshot();
      const header = () => document.querySelector<HTMLTableRowElement>('.work-package--results-tbody > tr[data-occurrence-key="group:0:header"]')!;
      const first = header();
      const sums = resultRow('1')!.nextElementSibling!;
      const timelineSums = () => document.querySelector<HTMLElement>('.wp-timeline-cell.__row-group-0:not([data-work-package-id])');
      expect(first).toHaveAttribute('opwptablerow');
      expect(first).toHaveTextContent('New');
      expect(resultRow('1')).toHaveAttribute('opwptablerow');
      expect(sums).toHaveAttribute('opwptablerow');
      expect(sums).toHaveTextContent('13');
      expect(timelineSums()).toBeVisible();

      fireEvent.click(first.querySelector('.expander')!);
      expect(header()).toBe(first);
      expect(first).toHaveAttribute('aria-expanded', 'false');
      expect(sums).not.toBeVisible();
      expect(timelineSums()).not.toBeVisible();

      workPackageTable.templateRows!.restore(before);
      expect(first.querySelector('.expander')).toHaveClass('icon-plus');

      await render(entries);

      expect(header()).toBe(first);
      expect(resultRow('1')!.nextElementSibling).toBe(sums);
      expect(sums).not.toBeVisible();
      expect(timelineSums()).not.toBeVisible();
      expect(resultRow('2')).toBeVisible();
    });

    it('renders the correct header for groups with the same normalized name', async () => {
      querySpace.groups.putValue([
        buildGroup({ ...newStatus, value: 'A+B' }, 'status', 0),
        buildGroup({ ...newStatus, value: 'A B' }, 'status', 1),
      ]);

      await mount({}, [{ id: '1', attributes: { status: 'A+B' } }, { id: '2', attributes: { status: 'A B' } }]);

      expect(resultRow('1')?.previousElementSibling).toHaveTextContent('A+B');
      expect(resultRow('2')?.previousElementSibling).toHaveTextContent('A B');
    });

    it('binds the row highlight and swaps it on refresh', async () => {
      const status = (id:string) => ({ status: { id, href: `/api/v3/statuses/${id}` } });
      const highlighting = TestBed.inject(WorkPackageViewHighlightingService);
      highlighting.update({ mode: 'status' });
      const table = await mount({}, [{ id: '1', attributes: status('11') }]);
      const row = resultRow('1')!;
      expect(row).toHaveClass(...Highlighting.backgroundClass('status', '11').split(' '));

      const readMode = vi.spyOn(highlighting, 'current', 'get');
      table.workPackageTable.refreshRows(buildWorkPackage({ id: '1', attributes: status('12') }));
      expect(readMode).not.toHaveBeenCalled();

      expect(row).toHaveClass(...Highlighting.backgroundClass('status', '12').split(' '));
      expect(row).not.toHaveClass(Highlighting.resourceClass('status', '11'));

      highlighting.update({ mode: 'none' });
      await waitFor(() => expect(row).not.toHaveClass(Highlighting.resourceClass('status', '12')));
      highlighting.update({ mode: 'status' });
      await waitFor(() => expect(row).toHaveClass(Highlighting.resourceClass('status', '12')));
    });

    describe('link cells', () => {
      const cell = () => resultRow('1')!.querySelector<HTMLTableCellElement>('td.customField1')!;
      const display = () => cell().querySelector<HTMLElement>('.inline-edit--display-field')!;
      const url = 'https://example.org/docs';

      beforeEach(() => {
        TestBed.inject(DisplayFieldService).addFieldType(LinkDisplayField, 'link', ['Link']);
        const cache = TestBed.inject(SchemaCacheService);
        const original = cache.of.bind(cache);
        vi.spyOn(cache, 'of').mockImplementation((resource) => {
          const schema = original(resource);
          const ofProperty = schema.ofProperty.bind(schema);
          return Object.assign(schema, {
            ofProperty: (name:string) => name === 'customField1'
              ? { type: 'Link', name: 'Reference', writable: true, hasDefault: false }
              : ofProperty(name),
          });
        });
        TestBed.inject(WorkPackageViewColumnsService).update(buildQuery(['id', 'subject', 'customField1'], null, false, false).columns);
      });

      it('retains the display while switching between empty, external and same-origin URLs', async () => {
        const { workPackageTable } = await mount({}, [{ id: '1', attributes: { customField1: '' } }]);
        const field = display();
        expect(cell()).toHaveAttribute('opwptabletextcell');
        expect(field).toHaveClass('-placeholder');
        expect(field).toHaveTextContent('-');
        expect(within(field).queryByRole('link')).toBeNull();

        const refresh = (value:string) => workPackageTable.refreshRows(buildWorkPackage({ id: '1', attributes: { customField1: value } }));
        refresh(url);
        const anchor = within(field).getByRole('link', { name: url });
        expect(display()).toBe(field);
        expect(field).not.toHaveClass('-placeholder');
        expect(field).toHaveAttribute('title', url);
        expect(anchor).toHaveAttribute('href', url);
        expect(anchor).toHaveAttribute('target', '_blank');
        expect(anchor).toHaveAttribute('rel', 'noopener noreferrer');
        expect(anchor).toHaveAttribute('tabindex', '-1');
        expect(field.querySelector('.inline-edit--display-trigger')).toBeNull();

        refresh('/help');
        expect(within(field).getByRole('link', { name: '/help' })).toBe(anchor);
        expect(anchor).toHaveAttribute('href', '/help');
        expect(anchor).toHaveAttribute('target', '');

        refresh('http://[');
        expect(anchor).toHaveAttribute('href', 'http://[');
        expect(anchor).toHaveAttribute('target', '');

        refresh('javascript:alert(1)');
        expect(anchor.getAttribute('href')).toMatch(/^unsafe:/);

        refresh('');
        expect(within(field).queryByRole('link')).toBeNull();
        expect(field).toHaveClass('-placeholder');
      });

      it('activates the edit affordance and preserves the editor across a link refresh', async () => {
        const attributes = { customField1: url, updateImmediately: vi.fn() };
        const { workPackageTable } = await mount({}, [{ id: '1', attributes }]);
        const root = cell();
        const edit = within(display()).getByRole('link', { name: 'Edit' });
        expect(root).toHaveAttribute('opwptabletextcell');
        expect(edit).toHaveClass('icon', 'icon-edit');
        expect(edit).toHaveAttribute('href', '#');
        expect(edit).toHaveAttribute('tabindex', '-1');

        fireEvent.click(edit);
        const input = await within(root).findByRole('textbox');
        const form = workPackageTable.editing.forms['1'];
        await waitFor(() => expect(form.activeFields.customField1).toBeDefined());
        fireEvent.input(input, { target: { value: 'Unsaved' } });

        const workPackage = states.workPackages.get('1').value!;
        Object.assign(workPackage, { customField1: '/updated' });
        workPackageTable.refreshRows(workPackage);
        expect(cell()).toBe(root);
        expect(within(root).getByRole('textbox')).toBe(input);
        expect(input).toHaveValue('Unsaved');

        form.activeFields.customField1.deactivate(false);
        expect(within(root).getByRole('link', { name: '/updated' })).toHaveAttribute('href', '/updated');
      });
    });

    describe('resource cells', () => {
      const resourceTypes:Record<string, string> = { status: 'Status', priority: 'Priority', type: 'Type', project: 'Project' };
      const cell = (attribute:string) => resultRow('1')!.querySelector<HTMLTableCellElement>(`td.${attribute}`)!;
      const display = (attribute:string) => cell(attribute).querySelector<HTMLElement>('.inline-edit--display-field')!;
      const hal = (type:string, id:string, name:string, href:string) => TestBed.inject(HalResourceService).createHalResource({
        _type: type, id, name, _links: { self: { href } },
      });

      beforeEach(() => {
        const fields = TestBed.inject(DisplayFieldService);
        fields.addFieldType(HighlightedResourceDisplayField, 'highlight', ['Status', 'Priority']);
        fields.addFieldType(TypeDisplayField, 'type', ['Type']);
        fields.addFieldType(ResourceDisplayField, 'resource', ['Project']);
        const cache = TestBed.inject(SchemaCacheService);
        const original = cache.of.bind(cache);
        vi.spyOn(cache, 'of').mockImplementation((resource) => {
          const schema = original(resource);
          const ofProperty = schema.ofProperty.bind(schema);
          return Object.assign(schema, {
            ofProperty: (name:string) => resourceTypes[name]
              ? { type: resourceTypes[name], name, writable: name === 'project', hasDefault: false }
              : ofProperty(name),
          });
        });
        TestBed.inject(WorkPackageViewColumnsService)
          .update(buildQuery(['id', 'subject', 'status', 'priority', 'type', 'project'], null, false, false).columns);
      });

      it('updates inline resource highlights without replacing the display spans', async () => {
        const highlighting = TestBed.inject(WorkPackageViewHighlightingService);
        const selectedAttributes = ['status', 'priority'].map((id) => hal('QueryColumn', id, id, `/api/v3/queries/columns/${id}`));
        highlighting.update({ mode: 'inline', selectedAttributes });
        const attributes = {
          status: hal('Status', '11', 'Open', '/api/v3/statuses/11'),
          priority: hal('Priority', '21', 'Normal', '/api/v3/priorities/21'),
          type: hal('Type', '31', 'Task', '/api/v3/types/31'),
          project: hal('Project', '41', 'Project A', '/api/v3/projects/41'),
        };
        const { workPackageTable } = await mount({}, [{ id: '1', attributes }]);
        const status = display('status');
        const priority = display('priority');
        const type = display('type');
        Object.keys(resourceTypes).forEach((attribute) => expect(cell(attribute)).toHaveAttribute('opwptabletextcell'));
        expect(status).toHaveClass(...Highlighting.inlineClass('status', '11').split(' '));
        expect(priority).toHaveClass(...Highlighting.inlineClass('priority', '21').split(' '));
        expect(type).toHaveClass(...Highlighting.inlineClass('type', '31').split(' '));
        expect(display('project')).toHaveTextContent('Project A');

        const readHighlighting = vi.spyOn(highlighting, 'current', 'get');
        attributes.status = hal('Status', '12', 'Closed', '/api/v3/statuses/12');
        workPackageTable.refreshRows(buildWorkPackage({ id: '1', attributes }));
        expect(readHighlighting).not.toHaveBeenCalled();
        expect(display('status')).toBe(status);
        expect(status).toHaveTextContent('Closed');
        expect(status).toHaveClass(Highlighting.resourceClass('status', '12'));
        expect(status).not.toHaveClass(Highlighting.resourceClass('status', '11'));

        const rendered = querySpace.tableRendered.value;
        workPackageTable.redrawTable();
        await waitFor(() => expect(querySpace.tableRendered.value).not.toBe(rendered));
        expect(readHighlighting).toHaveBeenCalledTimes(1);

        highlighting.update({ mode: 'inline', selectedAttributes: [selectedAttributes[1]] });
        await waitFor(() => expect(status).not.toHaveClass('__hl_dot'));
        expect(priority).toHaveClass(...Highlighting.inlineClass('priority', '21').split(' '));
        expect(type).toHaveClass(...Highlighting.inlineClass('type', '31').split(' '));

        highlighting.update({ mode: 'status' });
        await waitFor(() => expect(resultRow('1')).toHaveClass(...Highlighting.backgroundClass('status', '12').split(' ')));
        expect(status).not.toHaveClass('__hl_dot');
        expect(priority).not.toHaveClass('__hl_dot');
        expect(type).toHaveClass(...Highlighting.inlineClass('type', '31').split(' '));

        highlighting.update({ mode: 'none' });
        await waitFor(() => expect(resultRow('1')).not.toHaveClass('__hl_background'));
        expect(type).toHaveClass(...Highlighting.inlineClass('type', '31').split(' '));
      });

      it.each([{ selectedAttributes: undefined }, { selectedAttributes: [] }])('keeps only Type highlighted with inline selection $selectedAttributes', async ({ selectedAttributes }) => {
        TestBed.inject(WorkPackageViewHighlightingService).update({ mode: 'inline', selectedAttributes });
        await mount({}, [{
          id: '1',
          attributes: {
            status: hal('Status', '11', 'Open', '/api/v3/statuses/11'),
            priority: hal('Priority', '21', 'Normal', '/api/v3/priorities/21'),
            type: hal('Type', '31', 'Task', '/api/v3/types/31'),
          },
        }]);

        expect(display('status')).not.toHaveClass('__hl_dot');
        expect(display('priority')).not.toHaveClass('__hl_dot');
        expect(display('type')).toHaveClass(...Highlighting.inlineClass('type', '31').split(' '));
      });

      it('keeps text and empty placeholders for resources without highlight classes', async () => {
        TestBed.inject(WorkPackageViewHighlightingService)
          .update({ mode: 'inline', selectedAttributes: [hal('QueryColumn', 'status', 'status', '/api/v3/queries/columns/status')] });
        await mount({}, [{ id: '1', attributes: { status: { id: '11', name: 'Open' }, project: null } }]);

        expect(cell('status')).toHaveAttribute('opwptabletextcell');
        expect(display('status')).toHaveTextContent('Open');
        expect(display('status')).not.toHaveClass('__hl_dot');
        expect(cell('project')).toHaveAttribute('opwptabletextcell');
        expect(display('project')).toHaveClass('-placeholder');
        expect(display('project')).toHaveTextContent('-');
      });

      it.each([false, true])('retains an open project editor when undisclosed state changes from %s', async (initiallyUndisclosed) => {
        const disclosed = hal('Project', '41', 'Project A', '/api/v3/projects/41');
        const undisclosed = hal('Project', '42', 'Undisclosed', URN_UNDISCLOSED);
        const { workPackageTable } = await mount({}, [{ id: '1', attributes: { project: initiallyUndisclosed ? undisclosed : disclosed } }]);
        const before = cell('project');
        expect(before.hasAttribute('opwptabletextcell')).toBe(!initiallyUndisclosed);
        expect(display('project').querySelector('.color-fg-subtle')?.textContent ?? null).toBe(initiallyUndisclosed ? 'Undisclosed' : null);
        const workPackage = states.workPackages.get('1').value!;
        const form = workPackageTable.editing.startEditing(workPackage, 'wp-row-1');
        const field = await form.activate('project');
        const input = within(before).getByRole('textbox');
        fireEvent.input(input, { target: { value: 'Unsaved' } });

        Object.assign(workPackage, { project: initiallyUndisclosed ? disclosed : undisclosed });
        workPackageTable.refreshRows(workPackage);

        expect(cell('project')).toBe(before);
        expect(within(before).getByRole('textbox')).toBe(input);
        expect(input).toHaveValue('Unsaved');
        field!.deactivate(false);

        expect(cell('project').hasAttribute('opwptabletextcell')).toBe(initiallyUndisclosed);
        expect(within(cell('project')).queryByRole('textbox')).toBeNull();
        expect(display('project')).toHaveTextContent(initiallyUndisclosed ? 'Project A' : 'Undisclosed');
        expect(display('project').querySelector('.color-fg-subtle')?.textContent ?? null).toBe(initiallyUndisclosed ? null : 'Undisclosed');
      });
    });

    it('renders the context menu action as a Primer icon button outside the Tab order', async () => {
      await mount({ actionsColumnEnabled: true, contextMenuEnabled: true }, [{ id: '1' }]);

      const button = await within(resultRow('1')!).findByRole('button', { name: 'Open context menu' });
      expect(button).toHaveClass('Button--iconOnly', 'Button--invisible', 'wp-table-context-menu-link');
      expect(button).toHaveAttribute('tabindex', '-1');
      expect(button.closest('td')).toHaveClass('wp-table--context-menu-td', 'wp-table--navigable-cell');
    });

    it('opens the action menu from the Primer context menu button', async () => {
      await mount({ actionsColumnEnabled: true, contextMenuEnabled: true }, [{ id: '1' }]);
      const show = vi.spyOn(TestBed.inject(OpActionMenuService), 'show').mockImplementation(() => undefined);

      fireEvent.click(await within(resultRow('1')!).findByRole('button', { name: 'Open context menu' }));

      expect(show).toHaveBeenCalledOnce();
    });

    it('keeps separate template occurrences of a target shared by two relation rows', async () => {
      const columns = buildQuery(['id', 'subject', { id: 'follows', relationType: 'follows' }], null, false, true).columns;
      TestBed.inject(WorkPackageViewColumnsService).update(columns);
      TestBed.inject(WorkPackageViewTimelineService).setVisible(true);
      const table = await mount({}, [{ id: '1' }, { id: '2' }, { id: '3' }]);
      const occurrence = (key:string) => document.querySelector<HTMLTableRowElement>(`.work-package--results-tbody > tr[data-occurrence-key="${key}"]`);
      const toggle = (source:string) => fireEvent.click(occurrence(`wp:${source}`)!.querySelector('.wp-table--relation-indicator')!);
      expect(occurrence('wp:1')).toHaveAttribute('opwptablerow');

      toggle('1');
      await waitFor(() => expect(occurrence('relation:ofType:1:3')).toBeInTheDocument());
      const first = occurrence('relation:ofType:1:3')!;
      expect(first).toHaveAttribute('opwptablerow');
      expect(first).toHaveAttribute('aria-level', '2');
      expect(first.previousElementSibling).toBe(occurrence('wp:1'));
      expect(first.querySelector('.relation-row--type-label')).toHaveTextContent('Task');
      expect(first.querySelector('.wp-table--relation-indicator')).toBeNull();

      toggle('2');
      await waitFor(() => expect(occurrence('relation:ofType:2:3')).toBeInTheDocument());
      const second = occurrence('relation:ofType:2:3')!;
      const target = occurrence('wp:3')!;
      expect(occurrence('relation:ofType:1:3')).toBe(first);
      expect(second.previousElementSibling).toBe(occurrence('wp:2'));
      expect(document.querySelector('.wp-timeline-cell.wp-relation-row-1-to-3')).toBeInTheDocument();
      expect(document.querySelector('.wp-timeline-cell.wp-relation-row-2-to-3')).toBeInTheDocument();

      const renders = vi.spyOn(table, 'renderRows');
      table.workPackageTable.refreshRows(buildWorkPackage({ id: '3', subject: 'Renamed target' }));
      expect(renders).toHaveBeenCalledTimes(1);
      [first, second, target].forEach((row) => expect(within(row).getByRole('rowheader', { name: 'Renamed target' })).toBeInTheDocument());

      toggle('1');
      await waitFor(() => expect(first).not.toBeInTheDocument());
      expect(occurrence('relation:ofType:2:3')).toBe(second);
      expect(occurrence('wp:3')).toBe(target);
      expect(document.querySelector('.wp-timeline-cell.wp-relation-row-1-to-3')).toBeNull();
    });

    it('renders child relation rows from the same template list', async () => {
      const columns = buildQuery(['id', 'subject', { id: 'children', children: true }], null, false, false).columns;
      TestBed.inject(WorkPackageViewColumnsService).update(columns);
      await mount({}, [{ id: '1', children: [{ id: '2' }] }, { id: '2' }]);
      const parent = resultRow('1')!;
      fireEvent.click(parent.querySelector('.wp-table--relation-indicator')!);

      await waitFor(() => expect(parent.nextElementSibling).toHaveAttribute('data-occurrence-key', 'relation:children:1:2'));
      expect(parent.nextElementSibling).toHaveAttribute('opwptablerow');
      expect(parent.nextElementSibling?.querySelector('.relation-row--type-label')).toHaveTextContent('js.relation_labels.child');
    });

    it('renders drag handles and the drop placeholder for drag and drop tables', async () => {
      await mount({ dragAndDropEnabled: true }, [{ id: '1' }]);

      expect(resultRow('1')).toHaveAttribute('opwptablerow');
      expect(resultRow('1')!.querySelector('td.__internal-sorthandle .wp-table--drag-and-drop-handle')).toBeInTheDocument();

      await render([]);

      expect(document.querySelector('.work-package--results-tbody > tr.wp--placeholder-row'))
        .toHaveAttribute('data-occurrence-key', 'placeholder');
    });

    it('moves and restores rows through the template rows', async () => {
      const table = await mount({ dragAndDropEnabled: true }, [{ id: '1' }, { id: '2' }, { id: '3' }]);
      const rows = table.workPackageTable.templateRows!;
      const before = rows.snapshot();
      const ids = () => Array.from(document.querySelectorAll<HTMLElement>('.work-package--results-tbody > tr')).map((row) => row.dataset.workPackageId);

      rows.move('wp:3', 'wp:1', true);
      expect(ids()).toEqual(['3', '1', '2']);

      table.workPackageTable.refreshRows(buildWorkPackage({ id: '3', subject: 'Updated while moving' }));
      rows.restore(before);
      expect(ids()).toEqual(['1', '2', '3']);
      expect(within(resultRow('3')!).getByRole('rowheader', { name: 'Updated while moving' })).toBeInTheDocument();
    });

    it.each([false, true])('keeps an open editor when baseline eligibility changes from %s', async (initiallyChanged) => {
      let changed = initiallyChanged;
      vi.spyOn(TestBed.inject(WorkPackageViewBaselineService), 'isChanged').mockImplementation((_resource, attribute) => attribute === 'subject' && changed);
      const component = await mount({}, [{ id: '1', subject: 'Original', baseline: 'updated' }]);
      const table = component.workPackageTable;
      const cell = within(resultRow('1')!).getByRole('rowheader', { name: 'Original' });
      const workPackage = states.workPackages.get('1').value!;
      const form = table.editing.startEditing(workPackage, 'wp-row-1');
      const field = await form.activate('subject');
      const input = within(cell).getByRole('textbox');
      fireEvent.input(input, { target: { value: 'Unsaved' } });

      changed = !initiallyChanged;
      table.refreshRows(workPackage);

      expect(within(resultRow('1')!).getByRole('textbox')).toBe(input);
      expect(input).toHaveValue('Unsaved');
      field!.deactivate(false);
      const refreshed = within(resultRow('1')!).getByRole('rowheader', { name: 'Original' });
      expect(refreshed.hasAttribute('opwptabletextcell')).toBe(initiallyChanged);
      expect(within(refreshed).queryByRole('textbox')).toBeNull();
    });

    it('keeps a text cell editable after refresh, cancellation and reactivation', async () => {
      const component = await mount({}, [{ id: '1', subject: 'Original' }]);
      const table = component.workPackageTable;
      const row = resultRow('1')!;
      const cell = within(row).getByRole('rowheader', { name: 'Original' });
      expect(cell).toHaveAttribute('opwptabletextcell');
      const workPackage = states.workPackages.get('1').value!;
      const form = table.editing.startEditing(workPackage, 'wp-row-1');
      const field = await form.activate('subject');
      expect(field).toBeTruthy();
      const input = within(cell).getByRole('textbox');
      fireEvent.input(input, { target: { value: 'Unsaved' } });
      expect(cell.querySelector('.inline-edit--display-field')).toBeNull();

      expect(cell).toHaveClass(editModeClassName);
      table.refreshRows(workPackage);
      expect(cell).toHaveClass(editModeClassName);

      expect(within(cell).getByRole('textbox')).toBe(input);
      expect(input).toHaveValue('Unsaved');
      field!.deactivate(false);
      expect(within(cell).queryByRole('textbox')).toBeNull();
      expect(cell.querySelector('.inline-edit--display-field')).toHaveTextContent('Original');
      expect(within(row).getByRole('rowheader', { name: 'Original' })).toBe(cell);

      const reopened = await form.activate('subject');
      expect(within(cell).getByRole('textbox')).not.toBe(input);
      reopened!.deactivate(false);
      expect(cell.querySelector('.inline-edit--display-field')).toHaveTextContent('Original');
    });

    it('assigns native text cell layout classes by column ID', async () => {
      const layouts = new Map([
        ['id', 'id'],
        ['subject', 'subject -max'],
        ['startDate', 'startDate -no-ellipsis'],
        ['dueDate', 'dueDate -no-ellipsis'],
        ['duration', 'duration -no-ellipsis'],
        ['estimatedTime', 'estimatedTime -min-200'],
        ['remainingTime', 'remainingTime -min-200'],
        ['status', 'status'],
        ['customField1', 'customField1'],
      ]);
      const columns = [...layouts.keys()];
      const textFieldAliases = new Map([['startDate', 'plannedStart'], ['dueDate', 'plannedFinish']]);
      const cache = TestBed.inject(SchemaCacheService);
      const original = cache.of.bind(cache);
      vi.spyOn(cache, 'of').mockImplementation((resource) => {
        const schema = original(resource);
        const ofProperty = schema.ofProperty.bind(schema);
        const mappedName = schema.mappedName.bind(schema);
        return Object.assign(schema, {
          ofProperty: (name:string) => ofProperty(name) ?? { type: 'String', name, writable: false, hasDefault: false },
          mappedName: (name:string) => textFieldAliases.get(name) ?? mappedName(name),
        });
      });
      TestBed.inject(WorkPackageViewColumnsService).update(buildQuery(columns, null, false, false).columns);
      await mount({}, [{ id: '1' }]);

      const row = resultRow('1')!;
      expect(row.querySelector('th[opwptabletextcell]')).toHaveClass('subject', '-max');
      layouts.forEach((classes, column) => {
        if (column === 'id' || column === 'subject') return;

        const cell = row.querySelector(`td[opwptabletextcell].${column}`);
        expect(cell, `Native ${column} cell`).toHaveClass(...classes.split(' '), 'wp-table--cell-td', 'wp-table--navigable-cell');
      });
      ['status', 'customField1'].forEach((column) => {
        const cell = row.querySelector(`td.${column}`);
        expect(cell).not.toHaveClass('-max');
        expect(cell).not.toHaveClass('-min-200');
        expect(cell).not.toHaveClass('-no-ellipsis');
      });
    });

    it('applies ID fields for retained rows through one presenter per view', async () => {
      const { workPackageTable } = await mount({}, [{ id: '1' }, { id: '2' }]);
      const apply = vi.spyOn(WorkPackageIdDisplayField.prototype, 'apply');
      const firstRow = resultRow('1');
      const secondRow = resultRow('2');
      const previous = querySpace.tableRendered.value;

      workPackageTable.redrawTable();
      await waitFor(() => expect(querySpace.tableRendered.value).not.toBe(previous));

      expect(resultRow('1')).toBe(firstRow);
      expect(resultRow('2')).toBe(secondRow);
      expect(apply).toHaveBeenCalledTimes(2);
      expect(new Set(apply.mock.contexts).size).toBe(1);
    });

    it('keeps the read-only marker from a failed activation when the display classes change', async () => {
      const { workPackageTable } = await mount({}, [{ id: '1', subject: '' }]);
      const row = resultRow('1')!;
      const display = row.querySelector<HTMLElement>('.inline-edit--display-field.subject')!;
      expect(display).toHaveClass('-editable', '-placeholder');
      const workPackage = states.workPackages.get('1').value!;
      const form = workPackageTable.editing.startEditing(workPackage, 'wp-row-1');
      vi.spyOn(form, 'activate').mockResolvedValue(undefined);
      fireEvent.click(display);
      await waitFor(() => expect(display).toHaveClass('-read-only'));

      workPackageTable.refreshRows(buildWorkPackage({ id: '1', subject: 'After' }));

      expect(row.querySelector('.inline-edit--display-field.subject')).toBe(display);
      expect(display).toHaveTextContent('After');
      expect(display).toHaveClass('-editable', '-read-only');
      expect(display).not.toHaveClass('-placeholder');
    });

    it('refreshes a row in place', async () => {
      const table = await mount({}, [{ id: '1', subject: 'Before' }]);
      const row = resultRow('1')!;

      table.workPackageTable.refreshRows(buildWorkPackage({ id: '1', subject: 'After' }));

      expect(resultRow('1')).toBe(row);
      expect(within(row).getByRole('rowheader', { name: 'After' })).toBeInTheDocument();
    });
  });
});
