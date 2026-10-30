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

import { Component, Injector, NO_ERRORS_SCHEMA, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { BehaviorSubject, config, of, Subject } from 'rxjs';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { States } from 'core-app/core/states/states.service';
import { QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC, QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageInlineCreateComponent } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.component';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import {
  buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices,
} from '../wp-fast-table/testing/table-harness';
import { buildWorkPackage, WorkPackageFixture } from '../wp-fast-table/testing/work-package-fixture';
import { WorkPackageTimelineTableController } from './timeline/container/wp-timeline-container.directive';
import { WorkPackagesTableComponent } from './wp-table.component';

/** Shows the table or the card view, as `wp-list-view` does when the viewport or query changes. */
@Component({
  template: '@if (showTable()) { <wp-table [configuration]="configuration" /> }',
  standalone: false,
})
class ListViewStandInComponent {
  showTable = signal(true);

  configuration:Record<string, boolean> = {
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

  describe.each([true, false])('on an enabled table with drag and drop %s', (drag) => {
    describe.each([true, false])('and baseline %s', (baseline) => {
      it.each([true, false])('renders the same columns in header, colgroup and rows with a trailing column %s', async (trailing) => {
        const { element, component } = await mount({
          keyboardNavigationEnabled: true,
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

  it('keeps the column arithmetic of a capability-off table', async () => {
    const { element, component } = await mount({ dragAndDropEnabled: true }, true);

    expect(element.querySelectorAll('thead th')).toHaveLength(queryColumns + 2);
    expect(element.querySelectorAll('colgroup col')).toHaveLength(queryColumns + 2 + 1);
    expect(component.numTableColumns).toBe(queryColumns + 2 + 1);
  });
});

@Component({
  template: '<input type="text" aria-label="Work package to reference">',
  standalone: true,
})
class ReferenceStandInComponent {}

/** Shows an enabled and a capability-off table on one page. */
@Component({
  template: '@for (configuration of configurations; track $index) { <wp-table [configuration]="configuration" /> }',
  standalone: false,
})
class TwoTablesStandInComponent {
  private readonly disabled:Record<string, boolean> = { ...new ListViewStandInComponent().configuration };

  configurations = [{ ...this.disabled, keyboardNavigationEnabled: true }, this.disabled];
}

describe('WorkPackagesTableComponent treegrid structure', () => {
  const translations = {
    'js.label_work_package_plural': 'Work packages',
    'js.label_sorting': 'Sorting',
    'js.toolbar.settings.configure_view': 'Configure view',
    'js.work_packages.table.summary': 'Table with rows of work package and columns of work package attributes.',
    'js.work_packages.table.grid_actions_header': 'Actions',
    'js.work_packages.table.grid_baseline_header': 'Comparison status',
    'js.work_packages.table.sorted_by': 'Sorted by %{criteria}.',
    'js.work_packages.table.sort_criterion_ascending': '%{column} ascending',
    'js.work_packages.table.sort_criterion_descending': '%{column} descending',
    'js.work_packages.table.sorted_manually': 'Sorted manually.',
    'js.inplace.errors.messages_on_field': 'This field is invalid: %{messages}',
    'js.button_cancel': 'Cancel',
  };
  const enabled = { keyboardNavigationEnabled: true };
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
      declarations: [WorkPackagesTableComponent, WorkPackageInlineCreateComponent, ListViewStandInComponent, TwoTablesStandInComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [], translations, editing: {} }),
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
    querySpace.results.putValue({ elements: resources, offset: 1, pageSize: 20, count: resources.length, total: resources.length } as unknown as WorkPackageCollectionResource);
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

  async function mount(configuration:Record<string, boolean>, fixtures:WorkPackageFixture[] = [{ id: '1' }, { id: '2' }]) {
    const listView = TestBed.createComponent(ListViewStandInComponent);
    fixture = listView;
    listView.componentInstance.configuration = { ...listView.componentInstance.configuration, ...configuration };
    document.body.appendChild(listView.nativeElement as HTMLElement);
    listView.detectChanges();
    registerTables();
    await render(fixtures);
    return tables()[0];
  }

  async function replaceTable(configuration:Record<string, boolean>) {
    const listView = fixture as ComponentFixture<ListViewStandInComponent>;
    listView.componentInstance.showTable.set(false);
    listView.detectChanges();
    listView.componentInstance.configuration = { ...new ListViewStandInComponent().configuration, ...configuration };
    listView.componentInstance.showTable.set(true);
    listView.detectChanges();
    registerTables();
    await render([{ id: '1' }]);
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
    it('names the enabled table and drops the legacy caption', async () => {
      await mount(enabled);
      const grid = screen.getByRole('treegrid', { name: 'Work packages' });

      expect(grid).toHaveAttribute('aria-multiselectable', 'true');
      expect(within(grid).queryByText(translations['js.work_packages.table.summary'])).not.toBeInTheDocument();
    });

    it('keeps the legacy caption and native table on a capability-off table', async () => {
      await mount({});
      const table = screen.getByRole('table');

      expect(table).not.toHaveAttribute('role');
      expect(table).not.toHaveAttribute('aria-multiselectable');
      expect(table).not.toHaveAttribute('aria-label');
      expect(table).not.toHaveAttribute('aria-describedby');
      expect(within(table).getByText(translations['js.work_packages.table.summary'])).toBeInTheDocument();
      expect(table.querySelector('#wp-table-sort-summary')).toBeInTheDocument();
      expect(table.querySelector('thead')).not.toHaveAttribute('role');
      expect(table.querySelector('thead tr')).not.toHaveAttribute('role');
      expect(table.querySelector('thead tr')).not.toHaveAttribute('aria-level');
      table.querySelectorAll('thead th').forEach((header) => {
        expect(header).not.toHaveAttribute('role');
        expect(header).not.toHaveAttribute('aria-sort');
      });
    });
  });

  it('repaints positions after Angular updates the header', async () => {
    const component = await mount(enabled);
    const painted:string[] = [];
    vi.spyOn(component.workPackageTable.rowPositions!, 'paint').mockImplementation(() => {
      painted.push(headerRow().getAttribute('aria-label') ?? headerRow().textContent ?? '');
      expect(headerRow().querySelector('[aria-sort="descending"]')).not.toBeNull();
    });

    sortBy(['subject', QUERY_SORT_BY_DESC]);

    expect(painted).not.toHaveLength(0);
  });

  describe('header structure', () => {
    it('exposes a level 1 header row inside a rowgroup', async () => {
      await mount(enabled);

      expect(headerRow().parentElement).toHaveAttribute('role', 'rowgroup');
      expect(headerRow()).toHaveAttribute('role', 'row');
      expect(headerRow()).toHaveAttribute('aria-level', '1');
      expect(headerRow()).not.toHaveAttribute('aria-selected');
      expect(headerRow()).not.toHaveAttribute('aria-expanded');
    });

    it('names the drag, baseline, query and actions column headers', async () => {
      baselineActive = true;
      await mount({ ...enabled, dragAndDropEnabled: true, actionsColumnEnabled: true });
      const headers = within(headerRow()).getAllByRole('columnheader');

      expect(headers).toHaveLength(5);
      ['Sorting', 'Comparison status', 'id', 'subject', 'Actions'].forEach((name, index) => {
        expect(headers[index]).toHaveAccessibleName(name);
      });
    });

    it('names the trailing header after the configuration control', async () => {
      await mount({ ...enabled, columnMenuEnabled: true });

      expect(within(headerRow()).getAllByRole('columnheader').at(-1)).toHaveAccessibleName('Configure view');
    });

    it('draws the focus ring of the header row on its sticky cells', async () => {
      await mount(enabled);
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
      await mount(enabled);

      sortBy(['subject', QUERY_SORT_BY_ASC], ['id', QUERY_SORT_BY_DESC]);
      expect(sortStates()).toEqual([null, 'ascending']);
      expect(screen.getByRole('treegrid')).toHaveAccessibleDescription('Sorted by subject ascending and id descending.');

      sortBy(['id', QUERY_SORT_BY_DESC], ['subject', QUERY_SORT_BY_ASC]);
      expect(sortStates()).toEqual(['descending', null]);
      expect(screen.getByRole('treegrid')).toHaveAccessibleDescription('Sorted by id descending and subject ascending.');
    });

    it('describes a primary criterion whose column is not displayed', async () => {
      await mount(enabled);

      sortBy(['status', QUERY_SORT_BY_ASC], ['id', QUERY_SORT_BY_ASC], ['subject', QUERY_SORT_BY_DESC]);

      expect(sortStates()).toEqual([null, null]);
      expect(screen.getByRole('treegrid'))
        .toHaveAccessibleDescription('Sorted by status ascending, id ascending, and subject descending.');
    });

    it('describes manual sorting', async () => {
      await mount(enabled);

      sortBy(['manualSorting', QUERY_SORT_BY_ASC]);

      expect(sortStates()).toEqual([null, null]);
      expect(screen.getByRole('treegrid')).toHaveAccessibleDescription('Sorted manually.');
    });
  });

  describe('instances', () => {
    it('clears treegrid semantics when a capability-off table replaces an enabled one', async () => {
      const previous = await mount(enabled);
      sortBy(['subject', QUERY_SORT_BY_ASC]);
      const previousId = previous.workPackageTable.domId;

      await replaceTable({});

      expect(screen.queryByRole('treegrid')).not.toBeInTheDocument();
      expect(screen.getByRole('table')).not.toHaveAttribute('role');
      expect(document.querySelector(`[id^="${previousId}"]`)).not.toBeInTheDocument();
      expect(referencedIds(document).filter((id) => id.startsWith(previousId))).toEqual([]);
    });

    it('keeps a capability-off table beside an enabled one native, with unique references', async () => {
      fixture = TestBed.createComponent(TwoTablesStandInComponent);
      document.body.appendChild(fixture.nativeElement as HTMLElement);
      fixture.detectChanges();
      registerTables();
      await render([{ id: '1' }]);
      sortBy(['subject', QUERY_SORT_BY_ASC]);

      const [grid] = screen.getAllByRole('treegrid');
      const [table] = screen.getAllByRole('table');
      await waitFor(() => [grid, table].forEach((element) => {
        expect(element.querySelectorAll('tr.wp-table--row[data-work-package-id="1"]')).toHaveLength(1);
      }));
      expect(screen.getAllByRole('treegrid')).toHaveLength(1);
      expect(grid).toHaveAccessibleDescription('Sorted by subject ascending.');
      expect(table).not.toHaveAttribute('aria-describedby');
      expect(table.querySelectorAll('thead, tbody, tr, th, td')).not.toHaveLength(0);
      table.querySelectorAll('thead, tbody, tr, th, td').forEach((element) => {
        expect(element).not.toHaveAttribute('role');
        expect(element).not.toHaveAttribute('aria-level');
      });
      table.querySelectorAll('thead, tbody, tr').forEach((element) => {
        expect(element).not.toHaveAttribute('aria-selected');
        expect(element).not.toHaveAttribute('aria-expanded');
        expect(element).not.toHaveAttribute('aria-hidden');
      });

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
      await mount(enabled, []);
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

    it('keeps the native message row on a capability-off table', async () => {
      await mount({}, []);

      expect(emptySection()).not.toHaveAttribute('role');
      expect(emptySection()!.querySelector('tr')).not.toHaveAttribute('role');
      expect(emptySection()!.querySelector('tr')).not.toHaveAttribute('aria-level');
      expect(emptySection()!.querySelector('td')).not.toHaveAttribute('role');
    });
  });

  describe('inline create', () => {
    const inlineCreate = { ...enabled, inlineCreateEnabled: true, actionsColumnEnabled: true };
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

    it('repaints positions after permission and reference template changes', async () => {
      canReference.next(true);
      const component = await mount(inlineCreate);
      const painted = vi.spyOn(component.workPackageTable.rowPositions!, 'paint');
      painted.mockImplementation(() => {
        expect(createSection()).not.toHaveAttribute('aria-hidden');
      });

      fireEvent.click(within(createSection()).getByText('Reference an existing work package'));
      expect(painted).toHaveBeenCalled();
      expect(within(createSection()).getByRole('textbox', { name: 'Work package to reference' })).toBeInTheDocument();
      const exposure:(string|null)[] = [];
      painted.mockImplementation(() => exposure.push(createSection().getAttribute('aria-hidden')));
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
      component.workPackageTable.rowPositions!.paint();
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
      const positions = component.workPackageTable.rowPositions!;
      const paint = positions.paint.bind(positions);
      const counts:(string|null)[] = [];
      vi.spyOn(positions, 'paint').mockImplementation(() => {
        paint();
        if (createSection().querySelectorAll('tr').length === 2) counts.push(table.getAttribute('aria-rowcount'));
      });

      await openCreateRow();

      expect(counts).not.toHaveLength(0);
      expect(new Set(counts)).toEqual(new Set([null]));
    });

    it('stops repainting a removed table on permission changes', async () => {
      const component = await mount(inlineCreate);
      const painted = vi.spyOn(component.workPackageTable.rowPositions!, 'paint');
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
      const painted = vi.spyOn(component.workPackageTable.rowPositions!, 'paint');
      painted.mockImplementation(() => {
        expect(createRow()).toBeInTheDocument();
      });
      const row = await openCreateRow();
      expect(painted).toHaveBeenCalled();
      const editor = within(row).getByRole('textbox');
      editor.focus();
      const focused = document.activeElement;
      painted.mockRestore();
      component.workPackageTable.rowPositions!.paint();
      expect(document.activeElement).toBe(focused);

      const removed = vi.spyOn(component.workPackageTable.rowPositions!, 'paint').mockImplementation(() => {
        expect(createRow()).not.toBeInTheDocument();
      });
      fireEvent.keyDown(editor, { key: 'Escape' });
      expect(removed).toHaveBeenCalled();
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
      await mount({ ...enabled, inlineCreateEnabled: true });
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

    it('keeps the native create section on a capability-off table', async () => {
      await mount({ inlineCreateEnabled: true });
      const row = createSection().querySelector('tr')!;

      expect(createSection()).not.toHaveAttribute('role');
      expect(createSection()).not.toHaveAttribute('aria-hidden');
      expect(row).not.toHaveAttribute('role');
      expect(row).not.toHaveAttribute('aria-level');
      expect(row.querySelector('td')).not.toHaveAttribute('role');
    });

    it('keeps the native active create row on a capability-off table', async () => {
      await mount({ inlineCreateEnabled: true });
      const row = await openCreateRow();

      expect(row).not.toHaveAttribute('role');
      expect(row).not.toHaveAttribute('aria-level');
      Array.from(row.cells).forEach((cell) => expect(cell).not.toHaveAttribute('role'));
      expect(createSection()).not.toHaveAttribute('role');
    });
  });
});
