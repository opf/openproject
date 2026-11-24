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

import { ChangeDetectorRef, Component, Injector, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { Subject } from 'rxjs';
import { within } from '@testing-library/dom';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { nextTask } from 'core-common/testing/timing';
import { buildQuery, buildTable, FakeDragAndDropService, harnessProviders, initializeViewServices, scopeKeys, TableHarness } from '../../wp-fast-table/testing/table-harness';
import { totalsRowKey } from '../../wp-fast-table/row-keys';
import { WorkPackageTable } from '../../wp-fast-table/wp-fast-table';
import { WorkPackageTableSumsRowController } from './wp-table-sums-row.directive';

const sumsTemplate = '<table><tbody><tr class="wp-table--sums-row wp-table--row" wpTableSumsRow [wpTableSumsRow-table]="table()"></tr></tbody></table>';

@Component({ template: '', standalone: false })
class SumsHostComponent {
  table = signal<WorkPackageTable|undefined>(undefined);
}

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
      .overrideComponent(SumsHostComponent, { set: { template: sumsTemplate } })
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
    detectChanges();
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/schema' }, totalSums: {},
    } as unknown as WorkPackageCollectionResource);
  });

  afterEach(async () => {
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  function detectChanges() {
    fixture.changeDetectorRef.markForCheck();
    fixture.detectChanges();
  }

  async function resolveSchema() {
    schemaResponse.next(schema);
    await nextTask();
  }

  it('waits for the table input and replays the initial sums', async () => {
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    detectChanges();
    expect(loading).not.toHaveBeenCalled();
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
    await resolveSchema();
    expect(row).toHaveTextContent('js.label_total_sum');
    expect(loading).toHaveBeenCalledTimes(1);
  });

  it('stays hidden until a table is attached', () => {
    detectChanges();
    expect(row).toHaveClass('-hidden');
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
    expect(row).not.toHaveClass('-hidden');
  });

  it('ignores an already destroyed table input', async () => {
    const loading = vi.spyOn(directive.schemaCache, 'ensureLoaded');
    harness.table.destroy();
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
    detectChanges();
    await resolveSchema();
    expect(loading).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
  });

  it.each(['sums row', 'table'])('ignores schema completion after destroying the %s', async (owner) => {
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
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
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    fixture.componentInstance.table.set(replacement.table);
    detectChanges();
    replacement.table.destroy();
    await resolveSchema();
    expect(row).toBeEmptyDOMElement();
  });

  it('keeps a replacement input reacting when the previous table is destroyed', async () => {
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
    const replacement = buildTable({ workPackages: [] });
    tables.push(replacement);
    fixture.componentInstance.table.set(replacement.table);
    detectChanges();
    harness.table.destroy();
    await resolveSchema();
    expect(row).toHaveTextContent('js.label_total_sum');
    directive.wpTableSums.setEnabled(false);
    detectChanges();
    expect(row).toBeEmptyDOMElement();
  });

  it.each([
    ['rendering', true, 'js.label_total_sum'],
    ['clearing', false, ''],
  ])('captures focus ownership before %s the row and notifies the table after', async (_name, enabled, text) => {
    const events:string[] = [];
    row.innerHTML = '<td>previous</td>';
    vi.spyOn(harness.table.keyboardNavigation, 'captureOwnership').mockImplementation(() => { events.push(`capture:${row.textContent}`); });
    vi.spyOn(harness.table.keyboardNavigation, 'rowsChanged').mockImplementation(({ scope }) => { events.push(`refreshed:${scopeKeys(scope).join(',')}:${row.textContent}`); });
    directive.wpTableSums.setEnabled(enabled);
    detectChanges();
    fixture.componentInstance.table.set(harness.table);
    detectChanges();

    await resolveSchema();

    expect(events).toEqual([
      ...(enabled ? ['capture:previous', `refreshed:${totalsRowKey}:previous`] : []),
      'capture:previous', `refreshed:${totalsRowKey}:${text}`,
    ]);
  });

  it('leaves an already empty row alone when sums are off', async () => {
    const events:string[] = [];
    vi.spyOn(harness.table.keyboardNavigation, 'captureOwnership').mockImplementation(() => { events.push('capture'); });
    vi.spyOn(harness.table.keyboardNavigation, 'rowsChanged').mockImplementation(({ scope }) => { events.push(`refreshed:${scopeKeys(scope).join(',')}`); });
    directive.wpTableSums.setEnabled(false);
    detectChanges();
    fixture.componentInstance.table.set(harness.table);
    detectChanges();

    await resolveSchema();

    expect(row).toBeEmptyDOMElement();
    expect(events).toEqual(['capture', `refreshed:${totalsRowKey}`]);
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
      .overrideComponent(SumsHostComponent, { set: { template: sumsTemplate } })
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
    harness.tbody.closest('table')!.append(row.parentElement!);
    TestBed.inject(IsolatedQuerySpace).results.putValue({
      elements: [], sumsSchema: { href: '/api/v3/sums/schema' }, totalSums: { storyPoints: 34 },
    } as unknown as WorkPackageCollectionResource);
    return harness;
  };

  const attach = (harness:TableHarness, sums:boolean) => {
    directive.wpTableSums.setEnabled(sums);
    detectChanges();
    fixture.componentInstance.table.set(harness.table);
    detectChanges();
  };

  function detectChanges() {
    fixture.changeDetectorRef.markForCheck();
    fixture.detectChanges();
  }

  async function resolveSchema() {
    schemaResponse.next(schema);
    await nextTask();
  }

  const valueCell = () => within(row).getByText('34').closest('td')!;

  afterEach(async () => {
    fixture.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  it('repaints once per update, with the cells in place, before the row notification', async () => {
    const harness = await setUp({});
    const events:string[] = [];
    const paint = harness.table.painter.paint.bind(harness.table.painter);
    vi.spyOn(harness.table.painter, 'paint').mockImplementation((scope) => {
      events.push(`paint:${row.cells.length > 0}`);
      return paint(scope);
    });
    vi.spyOn(harness.table.keyboardNavigation, 'rowsChanged').mockImplementation(() => { events.push('notify'); });
    attach(harness, true);
    events.length = 0;

    await resolveSchema();

    expect(events).toEqual(['paint:true', 'notify']);
    events.length = 0;
    directive.wpTableSums.setEnabled(false);
    detectChanges();
    expect(events).toEqual(['paint:false', 'notify']);
  });

  it('mutates the totals row by its key', async () => {
    const harness = await setUp({});
    attach(harness, true);
    const mutated = harness.nextMutation().then(({ scope }) => scopeKeys(scope));

    await resolveSchema();

    expect(await mutated).toEqual([totalsRowKey]);
  });

  it('renders the cells while sums are on and empties the row again when they are off', async () => {
    const harness = await setUp({});
    attach(harness, false);

    expect(row).toBeEmptyDOMElement();

    directive.wpTableSums.setEnabled(true);
    detectChanges();
    await resolveSchema();

    expect(row.cells.length).toBeGreaterThan(0);

    directive.wpTableSums.setEnabled(false);
    detectChanges();

    expect(row).toBeEmptyDOMElement();
  });

  it('repaints only the replacement table after a pending schema resolves', async () => {
    const previous = await setUp({});
    attach(previous, true);
    const previousPaint = vi.spyOn(previous.table.painter, 'paint');
    const replacement = buildTable({ workPackages: [], configuration: {} });
    tables.push(replacement);
    replacement.tbody.closest('table')!.append(row.parentElement!);
    fixture.componentInstance.table.set(replacement.table);
    detectChanges();
    const replacementPaint = vi.spyOn(replacement.table.painter, 'paint');
    previous.table.destroy();

    await resolveSchema();

    expect(previousPaint).not.toHaveBeenCalled();
    expect(replacementPaint).toHaveBeenCalled();
    expect(row.cells.length).toBeGreaterThan(0);
  });

  it('keeps current sums when an older schema request completes last', async () => {
    const harness = await setUp({});
    const pending:(() => void)[] = [];
    const load = directive.schemaCache.ensureLoaded.bind(directive.schemaCache);
    vi.spyOn(directive.schemaCache, 'ensureLoaded').mockImplementation((resource) => load(resource)
      .then((loaded) => new Promise((resolve) => { pending.push(() => resolve(loaded)); })));
    attach(harness, true);
    await resolveSchema();

    const querySpace = TestBed.inject(IsolatedQuerySpace);
    querySpace.results.putValue({
      ...querySpace.results.value!, totalSums: { storyPoints: 55 },
    } as unknown as WorkPackageCollectionResource);
    detectChanges();
    await nextTask();
    expect(pending).toHaveLength(2);

    pending[1]();
    await nextTask();
    expect(within(row).getByText('55')).toBeInTheDocument();
    const painted = vi.spyOn(harness.table.painter, 'paint');

    pending[0]();
    await nextTask();

    expect(within(row).getByText('55')).toBeInTheDocument();
    expect(within(row).queryByText('34')).not.toBeInTheDocument();
    expect(painted).not.toHaveBeenCalled();
  });

  it('stays empty when the schema resolves after sums were disabled', async () => {
    const harness = await setUp({});
    attach(harness, true);
    directive.wpTableSums.setEnabled(false);
    detectChanges();
    const refreshed = vi.spyOn(harness.table.keyboardNavigation, 'rowsChanged');
    const painted = vi.spyOn(harness.table.painter, 'paint');

    await resolveSchema();

    expect(painted).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
    expect(refreshed).not.toHaveBeenCalled();
  });

  it('stays empty when the schema resolves after the table was destroyed', async () => {
    const harness = await setUp({});
    attach(harness, true);
    harness.table.destroy();
    const painted = vi.spyOn(harness.table.painter, 'paint');

    await resolveSchema();

    expect(painted).not.toHaveBeenCalled();
    expect(row).toBeEmptyDOMElement();
  });

  it.each([true, false])('names the totals row and describes its values with drag and drop %s', async (dragAndDropEnabled) => {
    const harness = await setUp({ dragAndDropEnabled });
    attach(harness, true);

    await resolveSchema();
    hostChangeDetector.detectChanges();

    expect(row).toHaveAccessibleName(expect.stringContaining('Total sum'));
    expect(row).toHaveAccessibleName(expect.stringContaining('34'));
    expect(within(row).getByText('Total sum').id).toBe(`${harness.table.domId}-sum-total`);
    expect(valueCell()).toHaveAccessibleDescription('Total sum');
  });
});
