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

import { CommonModule } from '@angular/common';
import { ApplicationRef, ChangeDetectionStrategy, ChangeDetectorRef, Component, ComponentRef, createComponent, EnvironmentInjector, Injector, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { of } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { WeekdayResourceService } from 'core-app/core/state/days/weekday.service';
import { QuerySortByResource, QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC } from 'core-app/features/hal/resources/query-sort-by-resource';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { nextTask } from 'core-common/testing/timing';
import { buildQuery, buildTable, FakeDragAndDropService, harnessProviders, initializeViewServices, TableHarness } from '../../wp-fast-table/testing/table-harness';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import { OpActionMenuTriggerDirective } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { headerRowKey } from 'core-app/features/work-packages/components/wp-fast-table/row-keys';
import { settlePopover } from 'core-common/testing/timing';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { SortHeaderDirective } from './sort-header.directive';
import { primarySortDirection } from './primary-sort-direction';

describe('SortHeaderDirective input readiness', () => {
  let fixture:ComponentFixture<SortHeaderDirective>;
  let harness:TableHarness;
  const tables:TableHarness[] = [];

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [SortHeaderDirective],
      imports: [CommonModule, OpActionMenuComponent, OpActionMenuTriggerDirective, DynamicIconDirective],
      schemas: [NO_ERRORS_SCHEMA],
      providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
    }).overrideComponent(SortHeaderDirective, {
      add: {
        providers: [
          WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
          { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
          { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
          { provide: OpModalService, useValue: {} },
          { provide: ConfirmDialogService, useValue: {} },
        ],
      },
    }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject'], null, false, false));
    harness = buildTable({ workPackages: [] });
    tables.push(harness);
    fixture = TestBed.createComponent(SortHeaderDirective);
    fixture.componentRef.setInput('headerColumn', TestBed.inject(WorkPackageViewSortByService).available[0]?.column
      ?? { id: 'subject', name: 'Subject', href: '/api/v3/queries/columns/subject', _type: 'QueryColumn' });
    fixture.componentRef.setInput('table', harness.table);
    TestBed.inject(IsolatedQuerySpace).available.sortBy.putValue([]);
  });

  afterEach(async () => {
    vi.useRealTimers();
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  function observeDetection() {
    const header = fixture.componentInstance as unknown as { cdRef:ChangeDetectorRef };
    return vi.spyOn(header.cdRef, 'detectChanges');
  }

  function sort() {
    const column = fixture.componentInstance.headerColumn;
    TestBed.inject(WorkPackageViewSortByService).update([
      { column, direction: { href: QUERY_SORT_BY_ASC } } as QuerySortByResource,
    ]);
  }

  it('shows a passive hierarchy glyph when column menus are disabled', async () => {
    fixture.componentRef.setInput('headerColumn', {
      id: 'subject', name: 'Subject', href: '/api/v3/queries/columns/subject', _type: 'QueryColumn',
    });
    TestBed.inject(WorkPackageViewHierarchiesService).setEnabled(true);
    fixture.detectChanges();
    await nextTask();
    fixture.detectChanges();

    const element = fixture.nativeElement as HTMLElement;
    expect(within(element).queryByRole('button')).toBeNull();
    expect(element.querySelector('svg.octicon-op-hierarchy')).toHaveAttribute('aria-hidden', 'true');
    const glyph = element.querySelector('svg.octicon-op-hierarchy')!.getBoundingClientRect();
    const label = element.querySelector('.wp-table--column-menu-name')!.getBoundingClientRect();
    expect(glyph.top + glyph.height / 2).toBeCloseTo(label.top + label.height / 2, 0);
  });

  it('cancels header setup when the header is destroyed before its task', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    fixture.detectChanges();
    const detect = observeDetection();
    const dom = vi.spyOn(fixture.componentInstance, 'setActiveColumnClass');
    const subscriptions = vi.spyOn(TestBed.inject(WorkPackageViewSortByService), 'onReadyWithAvailable');
    fixture.destroy();
    await vi.runAllTimersAsync();
    expect(detect).not.toHaveBeenCalled();
    expect(dom).not.toHaveBeenCalled();
    expect(subscriptions).not.toHaveBeenCalled();
  });

  it('ignores an already destroyed table input', async () => {
    fixture.componentRef.setInput('table', undefined);
    harness.table.destroy();
    fixture.componentRef.setInput('table', harness.table);
    fixture.detectChanges();
    const detect = observeDetection();
    const dom = vi.spyOn(fixture.componentInstance, 'setActiveColumnClass');
    const subscriptions = vi.spyOn(TestBed.inject(WorkPackageViewSortByService), 'onReadyWithAvailable');
    await nextTask();
    expect(detect).not.toHaveBeenCalled();
    expect(dom).not.toHaveBeenCalled();
    expect(subscriptions).not.toHaveBeenCalled();
  });

  it('cancels setup when its input table is destroyed before the task', async () => {
    fixture.detectChanges();
    const subscriptions = vi.spyOn(TestBed.inject(WorkPackageViewSortByService), 'onReadyWithAvailable');
    harness.table.destroy();
    await nextTask();
    expect(subscriptions).not.toHaveBeenCalled();
  });

  it('waits for a live input after the view is ready', async () => {
    fixture.componentRef.setInput('table', undefined);
    fixture.detectChanges();
    const subscriptions = vi.spyOn(TestBed.inject(WorkPackageViewSortByService), 'onReadyWithAvailable');
    await nextTask();
    expect(subscriptions).not.toHaveBeenCalled();
    fixture.componentRef.setInput('table', harness.table);
    fixture.detectChanges();
    await nextTask();
    sort();
    expect(fixture.nativeElement).toHaveClass('active-column');
    expect(subscriptions).toHaveBeenCalledTimes(1);
  });

  it('only initializes the replacement input when setup is queued', async () => {
    fixture.detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    const subscriptions = vi.spyOn(TestBed.inject(WorkPackageViewSortByService), 'onReadyWithAvailable');
    fixture.componentRef.setInput('table', replacement.table);
    fixture.detectChanges();
    harness.table.destroy();
    await nextTask();
    sort();
    expect(fixture.nativeElement).toHaveClass('active-column');
    expect(subscriptions).toHaveBeenCalledTimes(1);
  });

  it('unsubscribes initialized streams when replacing a still live input', async () => {
    fixture.detectChanges();
    await nextTask();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    const detect = observeDetection();
    fixture.componentRef.setInput('table', replacement.table);
    fixture.detectChanges();
    sort();
    expect(detect).not.toHaveBeenCalled();
    await nextTask();
    detect.mockClear();
    sort();
    expect(detect).toHaveBeenCalledTimes(1);
    harness.table.destroy();
    detect.mockClear();
    sort();
    expect(detect).toHaveBeenCalledTimes(1);
  });

  it('marks its column only while it is the primary criterion', async () => {
    fixture.detectChanges();
    await nextTask();
    const column = fixture.componentInstance.headerColumn;
    const status = { id: 'status', href: '/api/v3/queries/columns/status' } as QueryColumn;
    const sortBy = TestBed.inject(WorkPackageViewSortByService);

    sortBy.update([
      { column: status, direction: { href: QUERY_SORT_BY_ASC } },
      { column, direction: { href: QUERY_SORT_BY_DESC } },
    ] as QuerySortByResource[]);
    expect(fixture.nativeElement).not.toHaveClass('active-column');
    expect(fixture.componentInstance.directionClass).toBe('');

    sortBy.update([{ column, direction: { href: QUERY_SORT_BY_DESC } }] as QuerySortByResource[]);
    expect(fixture.nativeElement).toHaveClass('active-column');
    expect(fixture.componentInstance.directionClass).toBe('desc');
  });

  it.each(['header', 'table'])('stops all header streams after destroying the %s', async (owner) => {
    fixture.detectChanges();
    await nextTask();
    const detect = observeDetection();
    const dom = vi.spyOn(fixture.componentInstance, 'setActiveColumnClass');
    const baseline = fixture.debugElement.injector.get(WorkPackageViewBaselineService);
    const baselineEffects = vi.spyOn(baseline, 'isActive');
    if (owner === 'header') fixture.destroy();
    else harness.table.destroy();
    sort();
    TestBed.inject(WorkPackageViewGroupByService).disable();
    TestBed.inject(WorkPackageViewHierarchiesService).toggleState();
    baseline.update(['2026-10-01']);
    expect(detect).not.toHaveBeenCalled();
    expect(dom).not.toHaveBeenCalled();
    expect(baselineEffects).not.toHaveBeenCalled();
  });
});

describe('primarySortDirection', () => {
  const subject = { id: 'subject', href: '/api/v3/queries/columns/subject' } as QueryColumn;
  const status = { id: 'status', href: '/api/v3/queries/columns/status' } as QueryColumn;
  const criterion = (column:QueryColumn, href:string) => ({ column, direction: { href } }) as QuerySortByResource;

  it.each([
    [QUERY_SORT_BY_ASC, 'asc'],
    [QUERY_SORT_BY_DESC, 'desc'],
  ])('reads the primary criterion %s as %s', (href, expected) => {
    expect(primarySortDirection([criterion(subject, href), criterion(status, QUERY_SORT_BY_ASC)], subject)).toBe(expected);
  });

  it('ignores secondary criteria and unsorted columns', () => {
    const sortBy = [criterion(subject, QUERY_SORT_BY_ASC), criterion(status, QUERY_SORT_BY_DESC)];

    expect(primarySortDirection(sortBy, status)).toBeNull();
    expect(primarySortDirection([], subject)).toBeNull();
  });
});

describe('SortHeaderDirective relation columns', () => {
  let fixture:ComponentFixture<SortHeaderDirective>;
  let harness:TableHarness;

  const relationColumns = {
    toType: {
      id: 'relationsToType1',
      name: 'Relations to Bug',
      href: '/api/v3/queries/columns/relationsToType1',
      _type: 'QueryColumn::RelationToType',
      type: { name: 'Bug', href: '/api/v3/types/1' },
    },
    children: {
      id: 'children',
      name: 'Children',
      href: '/api/v3/queries/columns/children',
      _type: 'QueryColumn::RelationChild',
    },
  };

  async function render(column:object, columnMenuEnabled = true) {
    await TestBed.configureTestingModule({
      declarations: [SortHeaderDirective],
      imports: [CommonModule, OpTooltipDirective, OpActionMenuComponent, OpActionMenuTriggerDirective, DynamicIconDirective],
      schemas: [NO_ERRORS_SCHEMA],
      providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
    }).overrideComponent(SortHeaderDirective, {
      add: {
        providers: [
          WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
          { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
          { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
          { provide: OpModalService, useValue: {} },
          { provide: ConfirmDialogService, useValue: {} },
        ],
      },
    }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject'], null, false, false));
    harness = buildTable({ workPackages: [], configuration: { columnMenuEnabled } });
    fixture = TestBed.createComponent(SortHeaderDirective);
    fixture.componentRef.setInput('headerColumn', column);
    fixture.componentRef.setInput('table', harness.table);
    TestBed.inject(IsolatedQuerySpace).available.sortBy.putValue([]);
    fixture.detectChanges();
  }

  afterEach(async () => {
    fixture.destroy();
    await harness.destroy();
  });

  it('describes a type relation column header button with the full column name', async () => {
    await render(relationColumns.toType);

    await waitFor(() => expect(screen.getByRole('button', { name: 'Bug' })).toHaveAccessibleDescription('Relations to Bug'));
  });

  it('offers the column name as a label tooltip when the header text is the column name', async () => {
    await render(relationColumns.children);

    await waitFor(() => expect(screen.getByRole('button', { name: 'Children' })).toBeInTheDocument());
    expect(screen.getByRole('button', { name: 'Children' })).not.toHaveAccessibleDescription();
    const tooltip = () => document.querySelector(`tool-tip[for="${screen.getByRole('button', { name: 'Children' }).id}"]`);
    await waitFor(() => expect(tooltip()).toHaveAttribute('data-type', 'label'));
    expect(tooltip()).toHaveTextContent('Children');
  });

  it('renders no header button without a column menu', async () => {
    await render(relationColumns.toType, false);

    await waitFor(() => expect(screen.getByText('Bug')).toHaveAttribute('title', 'Relations to Bug'));
    expect(screen.queryByRole('button')).not.toBeInTheDocument();
    expect(fixture.nativeElement.querySelector('tool-tip')).toBeNull();
  });
});

@Component({
  template: `
    @for (table of tables; track $index) {
      <sortHeader [headerColumn]="column" [table]="table" />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
class TwoTablesHostComponent {
  column:object;

  tables:WorkPackageTable[];
}

describe('SortHeaderDirective relation columns in several tables', () => {
  const column = {
    id: 'relationsToType1',
    name: 'Relations to Bug',
    href: '/api/v3/queries/columns/relationsToType1',
    _type: 'QueryColumn::RelationToType',
    type: { name: 'Bug', href: '/api/v3/types/1' },
  };
  const tables:TableHarness[] = [];
  let fixture:ComponentFixture<TwoTablesHostComponent>;
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [TwoTablesHostComponent, SortHeaderDirective],
      imports: [CommonModule, OpTooltipDirective, OpActionMenuComponent, OpActionMenuTriggerDirective, DynamicIconDirective],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
        { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
        { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
        { provide: OpModalService, useValue: {} },
        { provide: ConfirmDialogService, useValue: {} },
      ],
    }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject'], null, false, false));
    tables.push(
      buildTable({ workPackages: [], configuration: { columnMenuEnabled: true } }),
      buildTable({ workPackages: [], configuration: { columnMenuEnabled: true } }),
    );
    fixture = TestBed.createComponent(TwoTablesHostComponent);
    fixture.componentInstance.column = column;
    fixture.componentInstance.tables = tables.map((harness) => harness.table);
    TestBed.inject(IsolatedQuerySpace).available.sortBy.putValue([]);
    fixture.detectChanges();
  });

  afterEach(async () => {
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
  });

  it('binds each header tooltip to its own button', async () => {
    await waitFor(() => expect(screen.getAllByRole('button', { name: 'Bug' })).toHaveLength(2));
    const buttons = screen.getAllByRole('button', { name: 'Bug' });

    await waitFor(() => buttons.forEach((button) => expect(button).toHaveAccessibleDescription('Relations to Bug')));
    expect(buttons[0].id).not.toEqual(buttons[1].id);
    buttons.forEach((button) => {
      expect(button.nextElementSibling).toHaveAttribute('for', button.id);
    });
  });

  // These headers render outside a table, so there is no origin cell to return to:
  // PVC's own focus return to the button is the final state here.
  it('returns focus to the header button whose column menu closed', async () => {
    await waitFor(() => expect(screen.getAllByRole('button', { name: 'Bug' })).toHaveLength(2));
    const second = screen.getAllByRole('button', { name: 'Bug' })[1];

    fireEvent.click(second);
    await settlePopover();
    const menu = within(second.closest('op-action-menu')!).getByRole('menu', { name: 'Relations to Bug', hidden: true });
    expect(menu.closest('anchored-position')!.matches(':popover-open')).toBe(true);
    expect(menu).toContainElement(document.activeElement as HTMLElement);

    fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
    await settlePopover();

    expect(second).toHaveFocus();
  });

  it('names a relation column menu after the column while its button is named by the tooltip', async () => {
    await waitFor(() => expect(screen.getAllByRole('button', { name: 'Bug' })).toHaveLength(2));

    expect(screen.getAllByRole('menu', { name: 'Relations to Bug', hidden: true })).toHaveLength(2);
    expect(screen.queryByRole('menu', { name: 'Bug', hidden: true })).toBeNull();
  });
});

describe('SortHeaderDirective column menu', () => {
  let harness:TableHarness;
  let refs:ComponentRef<SortHeaderDirective>[];
  let page:HTMLElement;
  let confirm:ReturnType<typeof vi.fn<ConfirmDialogService['confirm']>>;
  let showModal:ReturnType<typeof vi.fn<OpModalService['show']>>;
  let conditionallyLoadForm:ReturnType<typeof vi.fn<WorkPackagesListService['conditionallyLoadForm']>>;
  let menuOpenWhenCalled:boolean[];

  const settle = settlePopover;
  const columns = () => harness.injector.get(WorkPackageViewColumnsService);
  const header = (index:number) => harness.headerCells()[index];
  const button = (name:string) => within(harness.headerRow()).getByRole('button', { name });
  const menu = (name:string) => within(harness.headerRow()).getByRole('menu', { name, hidden: true });
  const overlay = (name:string) => menu(name).closest<HTMLElement>('anchored-position')!;
  const indicator = (index:number) => header(index).querySelector<SVGElement>('.wp-table--column-menu-indicator')!;
  const focusHeader = (index:number) => harness.table.keyboardNavigation.focusPosition({ key: headerRowKey, cell: index, desiredColumn: index });
  const open = async (name:string) => {
    fireEvent.click(button(name));
    await settle();
    return within(menu(name));
  };

  function mountHeaders():ComponentRef<SortHeaderDirective>[] {
    const appRef = harness.injector.get(ApplicationRef);
    return columns().getColumns().map((column, index) => {
      const host = document.createElement('sortHeader');
      header(index).replaceChildren(host);
      const ref = createComponent(SortHeaderDirective, { environmentInjector: harness.injector.get(EnvironmentInjector), hostElement: host });
      ref.setInput('headerColumn', column);
      ref.setInput('table', harness.table);
      appRef.attachView(ref.hostView);
      ref.changeDetectorRef.detectChanges();
      return ref;
    });
  }

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [SortHeaderDirective],
      imports: [CommonModule, OpTooltipDirective, OpActionMenuComponent, OpActionMenuTriggerDirective, DynamicIconDirective],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();
    menuOpenWhenCalled = [];
    confirm = vi.fn<ConfirmDialogService['confirm']>(() => {
      menuOpenWhenCalled.push(!!document.querySelector('anchored-position:popover-open'));
      return Promise.resolve();
    });
    conditionallyLoadForm = vi.fn<WorkPackagesListService['conditionallyLoadForm']>(() => new Promise(() => undefined));
    showModal = vi.fn<OpModalService['show']>(() => {
      menuOpenWhenCalled.push(!!document.querySelector('anchored-position:popover-open'));
      return undefined as never;
    });
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      columns: ['id', 'subject', 'status'],
      productionMarkup: true,
      configuration: { columnMenuEnabled: true },
      providers: [
        WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
        { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
        { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: { show: showModal } },
        { provide: ConfirmDialogService, useValue: { confirm } },
        { provide: WorkPackagesListService, useValue: { conditionallyLoadForm } },
      ],
    });
    await harness.render();
    harness.injector.get(IsolatedQuerySpace).available.sortBy.putValue([]);
    refs = mountHeaders();
    await nextTask();
    refs.forEach((ref) => ref.changeDetectorRef.detectChanges());
    page = document.createElement('div');
    page.textContent = 'Blank page';
    document.body.append(page);
  });

  afterEach(async () => {
    page.remove();
    refs.forEach((ref) => ref.destroy());
    await harness.destroy();
  });

  it('renders the header as one menu button with a hidden menu indicator', () => {
    const subject = button('subject');

    expect(subject).toHaveAttribute('aria-haspopup', 'menu');
    expect(subject).toHaveAttribute('aria-expanded', 'false');
    expect(subject).toHaveAttribute('aria-controls', menu('subject').id);
    expect(within(header(1)).queryByRole('link')).toBeNull();
    expect(getComputedStyle(indicator(1)).visibility).toBe('hidden');
  });

  it('shows the menu indicator while the header cell has keyboard focus', () => {
    focusHeader(1);

    expect(header(1)).toHaveFocus();
    expect(getComputedStyle(indicator(1)).visibility).toBe('visible');
  });

  it('opens the menu flush with the header cell\'s bottom and right edges', async () => {
    const cell = header(2);
    cell.style.width = '600px';

    await open('status');

    const menuRect = overlay('status').getBoundingClientRect();
    const cellRect = cell.getBoundingClientRect();
    expect(Math.round(menuRect.top)).toBe(Math.round(cellRect.bottom));
    expect(Math.round(menuRect.right)).toBe(Math.round(cellRect.right));
  });

  it('builds the items when the menu opens and clears them when it closes', async () => {
    const items = await open('subject');

    expect(items.getByRole('menuitem', { name: 'js.work_packages.query.hide_column' })).toBeInTheDocument();
    expect(button('subject')).toHaveAttribute('aria-expanded', 'true');

    fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
    await settle();

    expect(refs[1].instance.items()).toEqual([]);
    expect(button('subject')).toHaveAttribute('aria-expanded', 'false');
  });

  it('omits sorting and grouping for an ineligible column', async () => {
    vi.spyOn(harness.injector.get(WorkPackageViewSortByService), 'isSortable').mockReturnValue(false);
    vi.spyOn(harness.injector.get(WorkPackageViewGroupByService), 'isGroupable').mockReturnValue(false);

    const items = await open('id');

    expect(items.queryByRole('menuitem', { name: /sort_|query.group/ })).toBeNull();
    expect(items.getByRole('menuitem', { name: 'js.work_packages.query.hide_column' })).toBeInTheDocument();
  });

  it('rebuilds the items while the menu is open once a column becomes groupable', async () => {
    const available = harness.injector.get(IsolatedQuerySpace).available.groupBy;
    available.putValue([]);

    const items = await open('status');
    expect(items.queryByRole('menuitemcheckbox', { name: 'js.work_packages.query.group' })).toBeNull();

    available.putValue([{ id: 'status' } as QueryGroupByResource]);
    await nextTask();

    expect(items.getByRole('menuitemcheckbox', { name: 'js.work_packages.query.group' })).toHaveAttribute('aria-checked', 'false');
    expect(button('status')).toHaveAttribute('aria-expanded', 'true');
  });

  it('keeps focus on the same item when sorting arrives while the menu is open', async () => {
    const isSortable = vi.spyOn(harness.injector.get(WorkPackageViewSortByService), 'isSortable').mockReturnValue(false);
    const items = await open('status');
    items.getByRole('menuitem', { name: 'js.work_packages.query.hide_column' }).focus();

    isSortable.mockReturnValue(true);
    harness.injector.get(IsolatedQuerySpace).available.sortBy.putValue([]);
    await nextTask();

    expect(document.activeElement).toHaveTextContent('js.work_packages.query.hide_column');
    expect(items.getAllByRole('menuitem')[0]).toHaveTextContent('js.work_packages.query.sort_descending');
  });

  it('requests the query form when the menu opens before the form has loaded', async () => {
    await open('status');

    expect(conditionallyLoadForm).toHaveBeenCalledTimes(1);
  });

  it('stops refreshing an open menu when the header is destroyed', async () => {
    const available = harness.injector.get(IsolatedQuerySpace).available.groupBy;
    available.putValue([]);
    await open('status');
    const ref = refs.pop()!;
    ref.destroy();
    const items = ref.instance.items();

    available.putValue([{ id: 'status' } as QueryGroupByResource]);
    await nextTask();

    expect(ref.instance.items()).toBe(items);
  });

  it('shows the hierarchy checkbox on the subject menu and a passive glyph while enabled', async () => {
    harness.injector.get(WorkPackageViewHierarchiesService).setEnabled(true);
    await nextTask();
    refs[1].changeDetectorRef.detectChanges();

    const glyph = header(1).querySelector('.wp-table--column-menu-glyph');
    expect(glyph).toHaveAttribute('aria-hidden', 'true');
    expect(header(2).querySelector('.wp-table--column-menu-glyph')).toBeNull();

    const items = await open('subject');
    expect(items.getByRole('menuitemcheckbox', { name: 'js.toolbar.settings.display_hierarchy' })).toHaveAttribute('aria-checked', 'true');
    fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
    await settle();

    const status = await open('status');
    expect(status.queryByRole('menuitemcheckbox', { name: 'js.toolbar.settings.display_hierarchy' })).toBeNull();
  });

  it('Escape returns focus to the header cell', async () => {
    focusHeader(1);
    fireEvent.keyDown(header(1), { key: 'Enter' });
    await settle();
    expect(menu('subject')).toContainElement(document.activeElement as HTMLElement);

    fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
    await settle();

    expect(header(1)).toHaveFocus();
  });

  it('an action (move column) returns focus to the header cell, not the body', async () => {
    focusHeader(1);
    vi.spyOn(columns(), 'shift').mockImplementation(() => undefined);
    const items = await open('subject');

    fireEvent.click(items.getByRole('menuitem', { name: 'js.work_packages.query.move_column_right' }));
    await settle();

    expect(header(1)).toHaveFocus();
  });

  it('a moved column keeps focus on its header in the new position', async () => {
    focusHeader(1);
    const subject = header(1);
    vi.spyOn(columns(), 'shift').mockImplementation(() => header(0).before(subject));
    const items = await open('subject');

    fireEvent.click(items.getByRole('menuitem', { name: 'js.work_packages.query.move_column_left' }));
    await settle();

    expect(header(0)).toBe(subject);
    await waitFor(() => expect(subject).toHaveFocus());
  });

  it('hiding the last column focuses the previous header and arrow keys continue from it', async () => {
    focusHeader(2);
    vi.spyOn(columns(), 'removeColumn').mockImplementation(() => undefined);
    const items = await open('status');

    fireEvent.click(items.getByRole('menuitem', { name: 'js.work_packages.query.hide_column' }));
    await settle();

    await waitFor(() => expect(header(1)).toHaveFocus());
    fireEvent.keyDown(header(1), { key: 'ArrowLeft' });
    expect(header(0)).toHaveFocus();
  });

  it('hiding the first column focuses the next header', async () => {
    focusHeader(0);
    vi.spyOn(columns(), 'removeColumn').mockImplementation(() => undefined);
    const items = await open('id');

    fireEvent.click(items.getByRole('menuitem', { name: 'js.work_packages.query.hide_column' }));
    await settle();

    await waitFor(() => expect(header(1)).toHaveFocus());
  });

  it('closes before confirming a change from manual sorting', async () => {
    const sortBy = harness.injector.get(WorkPackageViewSortByService);
    vi.spyOn(sortBy, 'isManualSortingMode', 'get').mockReturnValue(true);
    vi.spyOn(sortBy, 'isSortable').mockReturnValue(true);
    const sort = vi.spyOn(sortBy, 'setAsSingleSortCriteria').mockImplementation(() => undefined);
    const items = await open('subject');

    fireEvent.click(items.getByRole('menuitem', { name: 'js.work_packages.query.sort_descending' }));

    expect(menuOpenWhenCalled).toEqual([false]);
    await waitFor(() => expect(sort).toHaveBeenCalledTimes(1));
  });

  it('closes before opening the columns dialog so the dialog owns focus', async () => {
    const dialog = document.createElement('button');
    document.body.append(dialog);
    showModal.mockImplementation(() => {
      menuOpenWhenCalled.push(!!document.querySelector('anchored-position:popover-open'));
      dialog.focus();
      return undefined as never;
    });
    const items = await open('subject');

    fireEvent.click(items.getByRole('menuitem', { name: 'js.work_packages.query.insert_columns' }));
    await settle();

    expect(menuOpenWhenCalled).toEqual([false]);
    expect(dialog).toHaveFocus();
    dialog.remove();
  });

  it('a click outside closes the menu and leaves focus where the popover restored it', async () => {
    focusHeader(1);
    await open('subject');

    fireEvent.pointerDown(page);
    fireEvent.mouseDown(page);
    overlay('subject').hidePopover();
    await settle();

    expect(overlay('subject').matches(':popover-open')).toBe(false);
    expect(menu('subject')).not.toContainElement(document.activeElement as HTMLElement);
    expect(button('subject')).not.toHaveFocus();
    expect(button('subject')).toHaveAttribute('aria-expanded', 'false');
  });
});
