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

import { ChangeDetectorRef, Component, Injector } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { firstValueFrom, Subject } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { within } from '@testing-library/dom';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { nextTask } from 'core-common/testing/timing';
import { buildQuery, buildTable, FakeDragAndDropService, harnessProviders, initializeViewServices, TableHarness } from '../../wp-fast-table/testing/table-harness';
import type { KeyboardNavigation } from '../../wp-fast-table/handlers/state/keyboard/keyboard-navigation-transformer';
import { totalsRowKey } from '../../wp-fast-table/handlers/state/keyboard/navigable-rows';
import { WorkPackageTableSumsRowController } from './wp-table-sums-row.directive';

@Component({ template: '<table><tbody><tr wpTableSumsRow></tr></tbody></table>', standalone: false })
class SumsHostComponent {}

describe('WorkPackageTableSumsRowController input readiness', () => {
  let fixture:ComponentFixture<SumsHostComponent>;
  let directive:WorkPackageTableSumsRowController;
  let row:HTMLTableRowElement;
  let harness:TableHarness;
  let schemaResponse:Subject<SchemaResource>;
  const tables:TableHarness[] = [];
  const schema = {} as SchemaResource;

  beforeEach(async () => {
    schemaResponse = new Subject<SchemaResource>();
    await TestBed.configureTestingModule({ declarations: [SumsHostComponent, WorkPackageTableSumsRowController], providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }) })
      .overrideDirective(WorkPackageTableSumsRowController, {
        add: {
          providers: [
            SchemaCacheService, WorkPackageViewSumService,
            { provide: HalResourceService, useValue: { createHalResourceOfClass: () => schema, get: () => schemaResponse } },
          ],
        },
      }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject'], null, false, false));
    harness = buildTable({ workPackages: [] });
    tables.push(harness);
    fixture = TestBed.createComponent(SumsHostComponent);
    const debug = fixture.debugElement.query(By.directive(WorkPackageTableSumsRowController));
    directive = debug.injector.get(WorkPackageTableSumsRowController);
    row = debug.nativeElement as HTMLTableRowElement;
    directive.wpTableSums.setEnabled(true);
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/schema' }, totalSums: {},
    } as unknown as WorkPackageCollectionResource);
  });

  afterEach(async () => {
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  async function resolveSchema() {
    schemaResponse.next(schema);
    await nextTask();
  }

  it('waits for the table input and replays the initial sums', async () => {
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    fixture.detectChanges();
    expect(loading).not.toHaveBeenCalled();
    directive.workPackageTable = harness.table;
    await resolveSchema();
    expect(row).toHaveTextContent('js.label_total_sum');
    expect(loading).toHaveBeenCalledTimes(1);
  });

  it('ignores an already destroyed table input', async () => {
    harness.table.destroy();
    directive.workPackageTable = harness.table;
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    fixture.detectChanges();
    await resolveSchema();
    expect(loading).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
  });

  it.each(['sums row', 'table'])('ignores schema completion after destroying the %s', async (owner) => {
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    if (owner === 'sums row') fixture.destroy();
    else harness.table.destroy();
    await resolveSchema();
    expect(row).toBeEmptyDOMElement();
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/another' }, totalSums: {},
    } as unknown as WorkPackageCollectionResource);
    expect(loading).not.toHaveBeenCalled();
  });

  it('ignores schema completion from the previous input', async () => {
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    directive.workPackageTable = replacement.table;
    replacement.table.destroy();
    await resolveSchema();
    expect(row).toBeEmptyDOMElement();
  });

  it('keeps a replacement input reacting when the previous table is destroyed', async () => {
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    directive.workPackageTable = replacement.table;
    harness.table.destroy();
    await resolveSchema();
    expect(row).toHaveTextContent('js.label_total_sum');
    directive.wpTableSums.setEnabled(false);
    expect(row).toBeEmptyDOMElement();
  });

  it.each([
    ['rendering', true, 'js.label_total_sum'],
    ['clearing', false, ''],
  ])('captures focus ownership before %s the row and notifies the table after', async (_name, enabled, text) => {
    const events:string[] = [];
    row.innerHTML = '<td>previous</td>';
    harness.table.keyboardNavigation = {
      captureOwnership: () => events.push(`capture:${row.textContent}`),
    } as unknown as KeyboardNavigation;
    harness.table.rowsRefreshed$.subscribe((key) => events.push(`refreshed:${key}:${row.textContent}`));
    directive.wpTableSums.setEnabled(enabled);
    directive.workPackageTable = harness.table;
    fixture.detectChanges();

    await resolveSchema();

    expect(events).toEqual(['capture:previous', `refreshed:${totalsRowKey}:${text}`]);
  });

  it('leaves an already empty row alone when sums are off', async () => {
    const events:string[] = [];
    harness.table.keyboardNavigation = {
      captureOwnership: () => events.push('capture'),
    } as unknown as KeyboardNavigation;
    harness.table.rowsRefreshed$.subscribe((key) => events.push(`refreshed:${key}`));
    directive.wpTableSums.setEnabled(false);
    directive.workPackageTable = harness.table;
    fixture.detectChanges();

    await resolveSchema();

    expect(row).toBeEmptyDOMElement();
    expect(events).toEqual([]);
  });
});

describe('WorkPackageTableSumsRowController semantics', () => {
  let fixture:ComponentFixture<SumsHostComponent>;
  let directive:WorkPackageTableSumsRowController;
  let hostChangeDetector:ChangeDetectorRef;
  let row:HTMLTableRowElement;
  let schemaResponse:Subject<SchemaResource>;
  const tables:TableHarness[] = [];
  const schema = {
    storyPoints: { type: 'Integer', name: 'storyPoints', writable: false, hasDefault: false },
  } as unknown as SchemaResource;

  const setUp = async (configuration:Record<string, boolean>) => {
    schemaResponse = new Subject<SchemaResource>();
    await TestBed.configureTestingModule({
      declarations: [SumsHostComponent, WorkPackageTableSumsRowController],
      providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [], translations: { 'js.label_total_sum': 'Total sum' } }),
    })
      .overrideDirective(WorkPackageTableSumsRowController, {
        add: {
          providers: [
            SchemaCacheService, WorkPackageViewSumService,
            { provide: HalResourceService, useValue: { createHalResourceOfClass: () => schema, get: () => schemaResponse } },
          ],
        },
      }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject', 'storyPoints'], null, false, false));
    const harness = buildTable({ workPackages: [], configuration });
    tables.push(harness);
    fixture = TestBed.createComponent(SumsHostComponent);
    const debug = fixture.debugElement.query(By.directive(WorkPackageTableSumsRowController));
    directive = debug.injector.get(WorkPackageTableSumsRowController);
    hostChangeDetector = debug.injector.get(ChangeDetectorRef);
    row = debug.nativeElement as HTMLTableRowElement;
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/schema' }, totalSums: { storyPoints: 34 },
    } as unknown as WorkPackageCollectionResource);
    return harness;
  };

  const attach = (harness:TableHarness, sums:boolean) => {
    directive.wpTableSums.setEnabled(sums);
    directive.workPackageTable = harness.table;
    fixture.detectChanges();
  };

  async function resolveSchema() {
    schemaResponse.next(schema);
    await nextTask();
  }

  const section = () => row.parentElement!;
  const valueCell = () => within(row).getByText('34').closest('td')!;

  afterEach(async () => {
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  it('repaints positions once per update and before the row notification', async () => {
    const harness = await setUp({ keyboardNavigationEnabled: true });
    const events:string[] = [];
    vi.spyOn(harness.table.rowPositions!, 'paint').mockImplementation(() => {
      events.push(`paint:${row.getAttribute('aria-hidden')}:${row.cells.length > 0}`);
      expect(row).toHaveAttribute('role', 'row');
    });
    harness.table.rowsRefreshed$.subscribe(() => events.push('notify'));
    attach(harness, true);
    events.length = 0;

    await resolveSchema();

    expect(events).toEqual(['paint:null:true', 'notify']);
    events.length = 0;
    directive.wpTableSums.setEnabled(false);
    expect(events).toEqual(['paint:true:false', 'notify']);
  });

  it('paints roles and exposure before notifying the table', async () => {
    const harness = await setUp({ keyboardNavigationEnabled: true });
    const painted = firstValueFrom(harness.table.rowsRefreshed$.pipe(take(1), map((key) => ({
      key,
      role: row.getAttribute('role'),
      level: row.getAttribute('aria-level'),
      cellRoles: Array.from(row.cells).map((cell) => cell.getAttribute('role')),
      rowHidden: row.getAttribute('aria-hidden'),
      sectionRole: section().getAttribute('role'),
      sectionHidden: section().getAttribute('aria-hidden'),
    }))));
    attach(harness, true);

    await resolveSchema();

    expect(await painted).toEqual({
      key: totalsRowKey,
      role: 'row',
      level: '1',
      cellRoles: Array.from(row.cells).map(() => 'gridcell'),
      rowHidden: null,
      sectionRole: 'rowgroup',
      sectionHidden: null,
    });
    expect(row.cells.length).toBeGreaterThan(0);
  });

  it('hides the empty row and section until its cells render, and again after clearing', async () => {
    const harness = await setUp({ keyboardNavigationEnabled: true });
    attach(harness, false);

    expect(row).toBeEmptyDOMElement();
    expect(row).toHaveAttribute('aria-hidden', 'true');
    expect(section()).toHaveAttribute('aria-hidden', 'true');

    directive.wpTableSums.setEnabled(true);
    await resolveSchema();

    expect(row).not.toHaveAttribute('aria-hidden');
    expect(section()).not.toHaveAttribute('aria-hidden');

    directive.wpTableSums.setEnabled(false);

    expect(row).toBeEmptyDOMElement();
    expect(row).toHaveAttribute('aria-hidden', 'true');
    expect(section()).toHaveAttribute('aria-hidden', 'true');
  });

  it('repaints only the replacement table after a pending schema resolves', async () => {
    const previous = await setUp({ keyboardNavigationEnabled: true });
    attach(previous, true);
    const previousPaint = vi.spyOn(previous.table.rowPositions!, 'paint');
    const replacement = buildTable({ workPackages: [], configuration: { keyboardNavigationEnabled: true } });
    tables.push(replacement);
    directive.workPackageTable = replacement.table;
    const replacementPaint = vi.spyOn(replacement.table.rowPositions!, 'paint');
    previous.table.destroy();

    await resolveSchema();

    expect(previousPaint).not.toHaveBeenCalled();
    expect(replacementPaint).toHaveBeenCalled();
    expect(row).not.toHaveAttribute('aria-hidden');
  });

  it('stays hidden when the schema resolves after sums were disabled', async () => {
    const harness = await setUp({ keyboardNavigationEnabled: true });
    const refreshed = vi.fn();
    harness.table.rowsRefreshed$.subscribe(refreshed);
    attach(harness, true);
    directive.wpTableSums.setEnabled(false);
    const painted = vi.spyOn(harness.table.rowPositions!, 'paint');

    await resolveSchema();

    expect(painted).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
    expect(row).toHaveAttribute('aria-hidden', 'true');
    expect(section()).toHaveAttribute('aria-hidden', 'true');
    expect(refreshed).not.toHaveBeenCalled();
  });

  it('stays hidden when the schema resolves after the table was destroyed', async () => {
    const harness = await setUp({ keyboardNavigationEnabled: true });
    attach(harness, true);
    harness.table.destroy();
    const painted = vi.spyOn(harness.table.rowPositions!, 'paint');

    await resolveSchema();

    expect(painted).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
    expect(row).toHaveAttribute('aria-hidden', 'true');
    expect(section()).toHaveAttribute('aria-hidden', 'true');
  });

  it.each([true, false])('names the totals row and describes its values with drag and drop %s', async (dragAndDropEnabled) => {
    const harness = await setUp({ keyboardNavigationEnabled: true, dragAndDropEnabled });
    attach(harness, true);

    await resolveSchema();
    hostChangeDetector.detectChanges();

    expect(row).toHaveAccessibleName(expect.stringContaining('Total sum'));
    expect(row).toHaveAccessibleName(expect.stringContaining('34'));
    expect(within(row).getByText('Total sum').id).toBe(`${harness.table.domId}-sum-total`);
    expect(valueCell()).toHaveAccessibleDescription('Total sum');
  });

  it('leaves the totals row of a capability-off table untouched', async () => {
    const harness = await setUp({});
    attach(harness, true);

    await resolveSchema();

    expect(row).toHaveTextContent('Total sum');
    [row, section(), ...Array.from(row.cells)].forEach((node) => {
      ['role', 'aria-level', 'aria-hidden', 'aria-describedby'].forEach((name) => expect(node).not.toHaveAttribute(name));
    });
    expect(within(row).getByText('Total sum')).not.toHaveAttribute('id');
  });
});
