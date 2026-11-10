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
import { ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { of } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { WeekdayResourceService } from 'core-app/core/state/days/weekday.service';
import { QuerySortByResource, QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC } from 'core-app/features/hal/resources/query-sort-by-resource';
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
import { OpColumnsContextMenu } from 'core-app/shared/components/op-context-menu/handlers/op-columns-context-menu.directive';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
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
      imports: [CommonModule],
      schemas: [NO_ERRORS_SCHEMA],
      providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
    }).overrideComponent(SortHeaderDirective, {
      add: {
        providers: [
          WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
          { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
          { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
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
      imports: [CommonModule, OpTooltipDirective],
      schemas: [NO_ERRORS_SCHEMA],
      providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
    }).overrideComponent(SortHeaderDirective, {
      add: {
        providers: [
          WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
          { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
          { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
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
    expect(fixture.nativeElement.querySelector('tool-tip')).toHaveAttribute('data-type', 'label');
    expect(fixture.nativeElement.querySelector('tool-tip')).toHaveTextContent('Children');
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
      <sortHeader [headerColumn]="column"
        [table]="table"
        opColumnsContextMenu
        [opColumnsContextMenu-column]="column"
        [opColumnsContextMenu-table]="table" />
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
  let contextMenu:{ show:ReturnType<typeof vi.fn>, close:ReturnType<typeof vi.fn>, isActive:() => boolean };

  beforeEach(async () => {
    contextMenu = { show: vi.fn(), close: vi.fn(), isActive: () => false };
    await TestBed.configureTestingModule({
      declarations: [TwoTablesHostComponent, SortHeaderDirective, OpColumnsContextMenu],
      imports: [CommonModule, OpTooltipDirective],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
        { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
        { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
        { provide: OPContextMenuService, useValue: contextMenu },
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

  it('returns focus to the header button whose column menu closed', async () => {
    await waitFor(() => expect(screen.getAllByRole('button', { name: 'Bug' })).toHaveLength(2));
    const second = screen.getAllByRole('button', { name: 'Bug' })[1];

    fireEvent.click(second);
    expect(contextMenu.show).toHaveBeenCalledTimes(1);
    const [handler] = contextMenu.show.mock.calls[0] as [OpColumnsContextMenu];
    handler.onClose();

    expect(second).toHaveFocus();
  });
});
