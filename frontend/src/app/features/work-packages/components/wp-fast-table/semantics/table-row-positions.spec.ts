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

import { buildTable, TableHarness, TableHarnessOptions } from '../testing/table-harness';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { waitFor } from '@testing-library/dom';
import { nextTask } from 'core-common/testing/timing';
import { States } from 'core-app/core/states/states.service';
import { groupOccurrenceKey, type RenderDraft } from '../rendered-occurrence-ledger';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { environment } from '../../../../../../environments/environment';

function deferred<T>() {
  let resolve!:(value:T) => void;
  let reject!:(error:unknown) => void;
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

describe('TableRowPositions', () => {
  let harness:TableHarness;
  const mount = (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: [{ id: '21' }, { id: '22' }],
      productionMarkup: true,
      pagination: { offset: 2, pageSize: 20, total: 100 },
      ...options,
      configuration: { keyboardNavigationEnabled: true, ...options.configuration },
    });
    return harness.render();
  };
  const table = () => harness.tbody.closest('table')!;
  const captureMessage = vi.fn();
  const index = (row:Element) => row.getAttribute('aria-rowindex');
  const createRow = () => table().querySelector<HTMLTableRowElement>('tbody[wpInlineCreate] tr')!;
  const expectIndices = (rows:Element[], indices:string[]) => {
    expect(rows).toHaveLength(indices.length);
    rows.forEach((row, position) => expect(row).toHaveAttribute('aria-rowindex', indices[position]));
  };
  beforeEach(() => {
    captureMessage.mockReset();
    vi.stubGlobal('ErrorReporter', { captureMessage });
  });
  afterEach(async () => {
    vi.unstubAllGlobals();
    await harness?.destroy();
  });

  it('uses global positions and includes trailing totals and Create', async () => {
    await mount();
    harness.expectRowPositions(['1', '22', '23', '102', '103'], '103');
  });

  it('reprojects local structure without changing the body coordinates', async () => {
    await mount();
    harness.totalsRow().setAttribute('aria-hidden', 'true');
    harness.table.rowPositions!.paint();
    expect(harness.totalsRow()).not.toHaveAttribute('aria-rowindex');
    expect(harness.row('21')).toHaveAttribute('aria-rowindex', '22');
    expect(createRow()).toHaveAttribute('aria-rowindex', '102');
    expect(table()).toHaveAttribute('aria-rowcount', '102');
  });

  it('leaves nested tables alone', async () => {
    await mount();
    const nested = document.createElement('table');
    nested.innerHTML = '<tbody><tr aria-rowindex="7"><td>nested</td></tr></tbody>';
    harness.row('21').cells[0].append(nested);
    harness.table.rowPositions!.paint();
    expect(nested.rows[0]).toHaveAttribute('aria-rowindex', '7');
    expect(table()).toHaveAttribute('aria-rowcount', '103');
  });

  it('clears the whole family for an exposed unclassified row', async () => {
    await mount();
    const extra = table().createTBody().insertRow();
    extra.insertCell().textContent = 'Unclassified';
    harness.table.rowPositions!.paint();
    harness.expectNoRowPositions();
  });

  it('reports a foreign row once per table', async () => {
    await mount();
    table().createTBody().insertRow().insertCell().textContent = 'Unclassified';
    harness.table.rowPositions!.paint();
    harness.table.rowPositions!.paint();
    expect(captureMessage).toHaveBeenCalledExactlyOnceWith('Row positions withdrawn: foreign row', 'warning');
  });

  describe('when withdrawing', () => {
    const status = { href: '/api/v3/statuses/1' };
    const grouped = { workPackages: [{ id: '1', attributes: { status } }], pagination: { offset: 1, pageSize: 20, total: 1 }, groups: [{ value: 'G', href: status.href, count: 1 }] };
    const hierarchy = { workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }], showHierarchies: true };
    const recapture = (draft:RenderDraft = harness.table.ledger.beginRender()) => {
      const positions = harness.table.rowPositions!;
      positions.commit(positions.capture(draft));
      positions.paint();
    };
    const withdrawals:[string, () => Promise<unknown>][] = [
      ['withdrawn: foreign row', async () => {
        await mount();
        table().createTBody().insertRow().insertCell().textContent = 'Unclassified';
        harness.table.rowPositions!.paint();
      }],
      ['withdrawn: untrusted collection href', () => mount({
        workPackages: [{ id: '1', attributes: { status } }],
        pagination: { offset: 1, pageSize: 20, total: 1 },
        groups: [{ value: 'G', href: status.href, count: 1 }],
        collectionHref: '/api/v3/versions/3/work_packages',
      })],
      ['withdrawn: non-monotonic', async () => {
        await mount({ workPackages: [{ id: '1' }, { id: '2', ancestors: [{ id: '1' }] }], showHierarchies: true });
        harness.row('1').before(harness.row('2'));
        harness.table.rowPositions!.paint();
      }],
      ['withdrawn: group objects differ from collection', async () => {
        await mount(grouped);
        harness.querySpace.groups.putValue([...harness.querySpace.groups.value!]);
        recapture();
      }],
      ['withdrawn: invalid pagination', async () => {
        await mount(hierarchy);
        harness.querySpace.results.value!.offset = 0;
        recapture();
      }],
      ['withdrawn: duplicate occurrence keys', async () => {
        await mount(hierarchy);
        recapture({ occurrences: [{ key: 'wp:1' }, { key: 'wp:1' }] } as unknown as RenderDraft);
      }],
      ['withdrawn: header rows', async () => {
        await mount();
        table().tHead!.insertRow();
        harness.table.rowPositions!.paint();
      }],
      ['withdrawn: unsafe count', async () => {
        await mount();
        const ordinals = new Map([['wp:21', 21], ['wp:22', 22]]);
        harness.table.rowPositions!.commit({ kind: 'query', source: harness.querySpace.results.value!, body: { count: Number.MAX_SAFE_INTEGER, ordinals } });
        harness.table.rowPositions!.paint();
      }],
      ['not offered: rows await a matching collection', async () => {
        await mount();
        harness.table.originalRows.reverse();
        recapture();
      }],
      ['not offered: collection changed before render', async () => {
        await mount();
        vi.spyOn(harness.table.uiWork, 'frame').mockImplementation(() => undefined);
        void harness.render([{ id: '31' }]);
        harness.table.rowPositions!.paint();
      }],
      ['not offered: grouped hierarchy', () => mount({ ...grouped, showHierarchies: true })],
      ['not offered: grouped baseline', () => mount({ ...grouped, baseline: true })],
      ['not offered: expanded relation columns', async () => {
        harness = buildTable({
          workPackages: [{ id: '21' }], productionMarkup: true,
          pagination: { offset: 2, pageSize: 20, total: 100 },
          columns: ['id', 'subject', { id: 'children', children: true }],
          configuration: { keyboardNavigationEnabled: true },
        });
        harness.expand('999', 'children');
        await harness.render();
      }],
    ];

    const originalProduction = environment.production;
    let log:ReturnType<typeof vi.spyOn>;
    beforeEach(() => {
      environment.production = false;
      log = vi.spyOn(console, 'log').mockImplementation(() => undefined);
    });
    afterEach(() => {
      environment.production = originalProduction;
      log.mockRestore();
    });

    it.each(withdrawals)('logs the reason %s', async (reason, withdraw) => {
      await withdraw();
      harness.expectNoRowPositions();
      expect(log).toHaveBeenCalledWith(`[DEBUG] Row positions ${reason}`);
    });
  });

  it('keeps group continuation and collapsed gaps global', async () => {
    const status = { href: '/api/v3/statuses/1' };
    await mount({
      workPackages: [{ id: '3', attributes: { status } }, { id: '4', attributes: { status } }],
      pagination: { offset: 2, pageSize: 2, total: 5 },
      groups: [
        { value: 'G', href: status.href, count: 4, sums: { storyPoints: 5 } },
        { value: 'H', href: '/api/v3/statuses/2', count: 1, sums: { storyPoints: 2 } },
      ],
    });
    const header = () => harness.groupHeader(0);
    const sum = () => harness.table.ledger.byKey(groupOccurrenceKey(0, 'sums'))!.element!;
    expectIndices([header(), harness.row('3'), harness.row('4'), sum()], ['2', '5', '6', '7']);
    expect(harness.totalsRow()).toHaveAttribute('aria-rowindex', '11');
    expect(table()).toHaveAttribute('aria-rowcount', '12');
    harness.injector.get(WorkPackageViewCollapsedGroupsService).toggleGroupCollapseState(header().dataset.groupIdentifier!);
    expect(header()).toHaveAttribute('aria-rowindex', '2');
    expect(harness.totalsRow()).toHaveAttribute('aria-rowindex', '11');
    expect(table()).toHaveAttribute('aria-rowcount', '12');
  });

  it('rejects a group header that disagrees with the query rank', async () => {
    await mount({
      workPackages: [{ id: '5', attributes: { status: { href: '/api/v3/statuses/1' } } }],
      pagination: { offset: 3, pageSize: 2, total: 5 },
      groups: [
        { value: 'G', href: '/api/v3/statuses/1', count: 4 },
        { value: 'H', href: '/api/v3/statuses/2', count: 1 },
      ],
    });
    harness.expectNoRowPositions();
  });

  describe('in hierarchy mode', () => {
    const parent = { id: '1' };
    const child = { id: '2', ancestors: [parent] };
    const hierarchies = () => harness.injector.get(WorkPackageViewHierarchiesService);
    const mountHierarchy = (options:Partial<TableHarnessOptions> = {}) => mount({
      workPackages: [parent, child],
      showHierarchies: true,
      ...options,
    });

    it('numbers rows from the page offset with an unknown count', async () => {
      await mountHierarchy();
      harness.expectRowPositions(['1', '22', '23', '24', '25'], '-1');
    });

    it('numbers inserted ancestors like result rows', async () => {
      await mountHierarchy({ workPackages: [{ id: '5', ancestors: [parent] }] });
      expect(harness.rowIds()).toEqual(['1', '5']);
      expectIndices(harness.rows(), ['22', '23']);
      expect(table()).toHaveAttribute('aria-rowcount', '-1');
    });

    it('keeps indices when a parent collapses', async () => {
      await mountHierarchy({ workPackages: [parent, child, { id: '3' }] });
      hierarchies().collapse('1');
      await waitFor(() => expect(harness.row('1')).toHaveAttribute('aria-expanded', 'false'));
      expectIndices([harness.row('1'), harness.row('3')], ['22', '24']);
      expect(harness.totalsRow()).toHaveAttribute('aria-rowindex', '25');
      expect(table()).toHaveAttribute('aria-rowcount', '-1');
    });

    it('withdraws positions while rows are out of render order', async () => {
      await mountHierarchy();
      const restore = harness.row('2').nextSibling;
      harness.row('1').before(harness.row('2'));
      harness.table.rowPositions!.paint();
      harness.expectNoRowPositions();
      harness.tbody.insertBefore(harness.row('2'), restore);
      harness.table.rowPositions!.paint();
      harness.expectRowPositions(['1', '22', '23', '24', '25'], '-1');
    });

    it('counts the empty message with an unknown count', async () => {
      await mountHierarchy({ workPackages: [], pagination: { offset: 1, pageSize: 20, total: 0 } });
      const empty = document.createElement('tbody');
      empty.className = 'work-package--empty-tbody';
      const row = empty.insertRow();
      row.insertCell().textContent = 'No results';
      harness.tbody.before(empty);
      harness.table.rowPositions!.paint();
      expect(row).toHaveAttribute('aria-rowindex', '2');
      expect(table()).toHaveAttribute('aria-rowcount', '-1');
    });

    it('withdraws positions for grouped results', async () => {
      const status = { href: '/api/v3/statuses/1' };
      await mountHierarchy({
        workPackages: [{ id: '1', attributes: { status } }, { id: '2', ancestors: [parent], attributes: { status } }],
        groups: [{ value: 'G', href: status.href, count: 100 }],
      });
      harness.expectNoRowPositions();
    });

    it('withdraws positions while a relation column is expanded', async () => {
      await mountHierarchy({ columns: ['id', 'subject', { id: 'children', children: true }] });
      harness.expand('999', 'children');
      await harness.render();
      harness.expectNoRowPositions();
    });
  });

  it('does not activate capability-off consumers', async () => {
    await mount({ configuration: { keyboardNavigationEnabled: false } });
    expect(harness.table.rowPositions).toBeNull();
    expect(table()).not.toHaveAttribute('aria-rowcount');
  });

  it('counts the genuinely empty message and excludes the drag placeholder', async () => {
    await mount({ workPackages: [], pagination: { offset: 1, pageSize: 20, total: 0 }, configuration: { dragAndDropEnabled: true } });
    const empty = document.createElement('tbody');
    empty.className = 'work-package--empty-tbody';
    const row = empty.insertRow();
    row.insertCell().textContent = 'No results';
    harness.tbody.before(empty);
    harness.table.rowPositions!.paint();
    expect(row).toHaveAttribute('aria-rowindex', '2');
    expect(harness.totalsRow()).toHaveAttribute('aria-rowindex', '3');
    expect(table()).toHaveAttribute('aria-rowcount', '4');
    expect(harness.tbody.rows[0]).not.toHaveAttribute('aria-rowindex');
  });

  it('does not label an out-of-range page as an empty query', async () => {
    await mount({ workPackages: [], pagination: { offset: 10, pageSize: 20, total: 100 } });
    const empty = document.createElement('tbody');
    empty.className = 'work-package--empty-tbody';
    empty.insertRow().insertCell().textContent = 'No results';
    harness.tbody.before(empty);
    harness.table.rowPositions!.paint();
    harness.expectNoRowPositions();
  });

  it('clears stale values for duplicate, backwards or missing descriptors', async () => {
    await mount();
    const variants:ReadonlyMap<string, number>[] = [
      new Map([['wp:21', 22], ['wp:22', 21]]),
      new Map([['wp:21', 21], ['wp:22', 21]]),
      new Map([['wp:21', 21]]),
    ];
    for (const ordinals of variants) {
      harness.table.rowPositions!.commit({ kind: 'query', source: harness.querySpace.results.value!, body: { count: 100, ordinals } });
      harness.table.rowPositions!.paint();
      harness.expectNoRowPositions();
    }
  });

  it('clears stale coordinates before a newer collection commits', async () => {
    await mount();
    const frames:(() => void)[] = [];
    vi.spyOn(harness.table.uiWork, 'frame').mockImplementation((callback) => { frames.push(callback); });
    const rendered = harness.render([{ id: '31' }, { id: '32' }]);
    harness.table.rowPositions!.paint();
    expect(table()).not.toHaveAttribute('aria-rowcount');
    expect(harness.row('21')).not.toHaveAttribute('aria-rowindex');
    frames.splice(0).forEach((callback) => callback());
    await rendered;
    expect(harness.row('31')).toHaveAttribute('aria-rowindex', '22');
    expect(table()).toHaveAttribute('aria-rowcount', '103');
  });

  it('paints replacement work-package rows before refresh notification', async () => {
    await mount();
    let observed:string|null = null;
    harness.table.rowsRefreshed$.subscribe(() => { observed = index(harness.row('21')); });
    const resource = harness.table.originalRowIndex['21'].object;
    harness.table.refreshRows(resource);
    expect(observed).toBe('22');
  });

  it('finds rendered rows without scanning the ledger', async () => {
    await mount();
    const scanned = vi.spyOn(harness.table.ledger, 'occurrences', 'get');
    harness.table.rowPositions!.paint();
    expect(scanned).not.toHaveBeenCalled();
    harness.expectRowPositions(['1', '22', '23', '102', '103'], '103');
  });

  it('skips the row scan while positions stay withdrawn', async () => {
    await mount();
    harness.table.rowPositions!.commit(null);
    harness.table.rowPositions!.paint();
    harness.expectNoRowPositions();
    const scanned = vi.spyOn(table(), 'rows', 'get');
    harness.table.rowPositions!.paint();
    expect(scanned).not.toHaveBeenCalled();
  });

  it('carries indices through many row refreshes without rescanning the table', async () => {
    await mount();
    const original = harness.row('21');
    vi.spyOn(harness.table.lastRenderPass!, 'refresh').mockImplementation((occurrence) => {
      const replacement = occurrence.element!.cloneNode(true) as HTMLTableRowElement;
      replacement.removeAttribute('aria-rowindex');
      occurrence.element!.replaceWith(replacement);
      return replacement;
    });
    const painted = vi.spyOn(harness.table.rowPositions!, 'paint');
    for (let refresh = 0; refresh < 50; refresh += 1) {
      harness.table.refreshRows(harness.table.originalRowIndex[refresh % 2 ? '22' : '21'].object);
    }
    expect(painted).not.toHaveBeenCalled();
    expect(harness.row('21')).not.toBe(original);
    harness.expectRowPositions(['1', '22', '23', '102', '103'], '103');
  });

  it('withdraws instead of carrying an index once the collection changed', async () => {
    await mount();
    vi.spyOn(harness.table.lastRenderPass!, 'refresh').mockImplementation((occurrence) => {
      const replacement = occurrence.element!.cloneNode(true) as HTMLTableRowElement;
      occurrence.element!.replaceWith(replacement);
      return replacement;
    });
    vi.spyOn(harness.table.uiWork, 'frame').mockImplementation(() => undefined);
    void harness.render([{ id: '21' }, { id: '22' }]);
    harness.table.refreshRows(harness.table.originalRowIndex['21'].object);
    harness.expectNoRowPositions();
  });

  it('stops painting after teardown', async () => {
    await mount();
    await harness.destroy();
    table().removeAttribute('aria-rowcount');
    harness.table.rowPositions!.paint();
    expect(table()).not.toHaveAttribute('aria-rowcount');
  });

  it('does not treat an offscreen expanded owner as zero additional rows', async () => {
    harness = buildTable({
      workPackages: [{ id: '21' }], productionMarkup: true,
      pagination: { offset: 2, pageSize: 20, total: 100 },
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      configuration: { keyboardNavigationEnabled: true },
    });
    harness.expand('999', 'relationsOfTypeFollows');
    await harness.render();
    expect(table()).not.toHaveAttribute('aria-rowcount');
  });

  describe('while a dragged row is staged', () => {
    let prepared:ReturnType<typeof deferred<void>>;
    let persisted:ReturnType<typeof deferred<void>>;
    const dragAction = {
      prepareDrop: () => prepared.promise.then(() => ({ persist: () => persisted.promise })),
    };
    const cleared = () => harness.expectNoRowPositions();
    const mountFlat = () => mount({ workPackages: [{ id: '21' }, { id: '22' }, { id: '23' }], dragAction });
    const staged = (ids:string[]) => waitFor(() => expect(harness.rowIds()).toEqual(ids));

    beforeEach(() => {
      prepared = deferred<void>();
      persisted = deferred<void>();
    });

    it('withdraws positions until preparation settles and restores them after it fails', async () => {
      await mountFlat();
      const dropping = harness.drop('21', '22', 'bottom');
      await staged(['22', '21', '23']);
      cleared();

      prepared.reject(new Error('prepare failed'));
      expect(await dropping).toBe(false);
      expect(harness.rowIds()).toEqual(['21', '22', '23']);
      expectIndices(harness.rows(), ['22', '23', '24']);
      expect(table()).toHaveAttribute('aria-rowcount', '103');
    });

    it('stays withdrawn during persistence and restores positions after it fails', async () => {
      await mountFlat();
      const dropping = harness.drop('21', '22', 'bottom');
      await staged(['22', '21', '23']);
      prepared.resolve();
      await nextTask();
      cleared();

      persisted.reject(new Error('persist failed'));
      expect(await dropping).toBe(false);
      expect(harness.rowIds()).toEqual(['21', '22', '23']);
      expectIndices(harness.rows(), ['22', '23', '24']);
    });

    it('waits for a matching collection after a successful drop', async () => {
      await mountFlat();
      const rebuilt = harness.nextRender();
      const dropping = harness.drop('21', '22', 'bottom');
      await staged(['22', '21', '23']);
      prepared.resolve();
      persisted.resolve();
      expect(await dropping).toBe(true);
      await rebuilt;
      expect(harness.rowIds()).toEqual(['22', '21', '23']);
      cleared();

      await harness.render([{ id: '22' }, { id: '21' }, { id: '23' }]);
      expectIndices(harness.rows(), ['22', '23', '24']);
      expect(table()).toHaveAttribute('aria-rowcount', '103');
    });

    it('keeps the moved row, its selection and tab stop while withdrawn', async () => {
      await mountFlat();
      const moved = harness.row('21');
      harness.click('21');
      expect(moved).toHaveAttribute('tabindex', '0');
      const dropping = harness.drop('21', '22', 'bottom');
      await staged(['22', '21', '23']);
      expect(harness.row('21')).toBe(moved);
      expect(moved).toHaveClass('-checked');
      expect(moved).toHaveAttribute('tabindex', '0');
      prepared.reject(new Error('prepare failed'));
      await dropping;
      expect(harness.row('21')).toBe(moved);
      expect(moved).toHaveClass('-checked');
      expect(moved).toHaveAttribute('tabindex', '0');
    });

    it('keeps grouped gaps when a staged move is put back', async () => {
      const status1 = { href: '/api/v3/statuses/1' };
      const status2 = { href: '/api/v3/statuses/2' };
      await mount({
        workPackages: [
          { id: '3', attributes: { status: status1 } },
          { id: '4', attributes: { status: status1 } },
          { id: '5', attributes: { status: status2 } },
        ],
        pagination: { offset: 1, pageSize: 3, total: 5 },
        groups: [
          { value: 'G', href: status1.href, count: 2 },
          { value: 'H', href: status2.href, count: 3 },
        ],
        dragAction,
      });
      expectIndices(harness.rows(), ['3', '4', '6']);
      const dropping = harness.drop('3', '5', 'bottom');
      await staged(['4', '5', '3']);
      cleared();
      prepared.reject(new Error('prepare failed'));
      await dropping;
      expectIndices(harness.rows(), ['3', '4', '6']);
      expect(table()).toHaveAttribute('aria-rowcount', '10');
    });

    it('withdraws hierarchy positions until preparation settles and restores them after it fails', async () => {
      await mount({ workPackages: [{ id: '21' }, { id: '22' }, { id: '23' }], showHierarchies: true, dragAction });
      const dropping = harness.drop('21', '22', 'bottom');
      await staged(['22', '21', '23']);
      cleared();

      prepared.reject(new Error('prepare failed'));
      expect(await dropping).toBe(false);
      expect(harness.rowIds()).toEqual(['21', '22', '23']);
      expectIndices(harness.rows(), ['22', '23', '24']);
      expect(table()).toHaveAttribute('aria-rowcount', '-1');
    });

    it('does not paint a torn-down table when a staged move settles', async () => {
      await mountFlat();
      const dropping = harness.drop('21', '22', 'bottom');
      await staged(['22', '21', '23']);
      await harness.destroy();
      prepared.reject(new Error('prepare failed'));
      expect(await dropping).toBe(false);
      expect(harness.rowIds()).toEqual(['22', '21', '23']);
      cleared();
    });
  });

  describe('with the children column', () => {
    const children = { id: 'children', children: true } as const;

    it('does not treat an offscreen expanded owner as zero additional rows', async () => {
      await mount({ workPackages: [{ id: '21' }], columns: ['id', 'subject', children] });
      harness.expand('999', 'children');
      await harness.render();
      expect(table()).not.toHaveAttribute('aria-rowcount');
      expect(harness.row('21')).not.toHaveAttribute('aria-rowindex');
    });

    it('stays absent while expanded children load and after they appear', async () => {
      let resolveLoad!:() => void;
      const loaded = new Promise<void>((resolve) => { resolveLoad = resolve; });
      harness = buildTable({
        workPackages: [{ id: '21', children: [{ id: '23' }] }, { id: '22' }],
        productionMarkup: true,
        pagination: { offset: 2, pageSize: 20, total: 100 },
        columns: ['id', 'subject', children],
        loadChildren: false,
        configuration: { keyboardNavigationEnabled: true },
        requireAll: async (ids) => {
          await loaded;
          return ids.map((id) => {
            const child = buildWorkPackage({ id });
            harness.injector.get(States).workPackages.get(id).putValue(child);
            return child;
          });
        },
      });
      harness.expand('21', 'children');
      await harness.render();
      expect(table()).not.toHaveAttribute('aria-rowcount');
      expect(harness.row('21')).not.toHaveAttribute('aria-rowindex');

      const redrawn = harness.nextRender();
      resolveLoad();
      await redrawn;
      expect(harness.relationRow('21', '23', 'children')).toBeInTheDocument();
      harness.expectNoRowPositions();
    });

    it('keeps global positions when nothing is expanded', async () => {
      await mount({ columns: ['id', 'subject', children] });
      expect(harness.row('21')).toHaveAttribute('aria-rowindex', '22');
      expect(table()).toHaveAttribute('aria-rowcount', '103');
    });
  });


  it('publishes indices from the accepted render instead of a superseded frame', async () => {
    await mount();
    const frames:(() => void)[] = [];
    vi.spyOn(harness.table.uiWork, 'frame').mockImplementation((callback) => { frames.push(callback); });
    const first = harness.render([{ id: '31' }]);
    const second = harness.render([{ id: '41' }, { id: '42' }]);
    const publications:(string|null)[][] = [];
    const subscription = harness.querySpace.tableRendered.values$().subscribe(() => {
      publications.push(harness.rows().map(index));
    });
    frames.splice(0).forEach((callback) => callback());
    await Promise.all([first, second]);
    subscription.unsubscribe();
    expect(harness.rowIds()).toEqual(['41', '42']);
    expect(publications.at(-1)).toEqual(['22', '23']);
  });

  it('clears indices when group counts do not match the query total', async () => {
    const status = { href: '/api/v3/statuses/1' };
    await mount({
      workPackages: [{ id: '1', attributes: { status } }],
      pagination: { offset: 1, pageSize: 20, total: 10 },
      groups: [{ value: 'G', href: status.href, count: 2 }],
    });
    expect(table()).not.toHaveAttribute('aria-rowcount');
    expect(harness.row('1')).not.toHaveAttribute('aria-rowindex');
  });

  it.each([
    '/api/v3/work_packages?offset=1',
    '/api/v3/projects/12/work_packages',
    '/api/v3/workspaces/12/work_packages?pageSize=20',
  ])('trusts grouped aggregates of the primary collection %s', async (collectionHref) => {
    const status = { href: '/api/v3/statuses/1' };
    await mount({
      workPackages: [{ id: '1', attributes: { status } }],
      pagination: { offset: 1, pageSize: 20, total: 1 },
      groups: [{ value: 'G', href: status.href, count: 1 }],
      collectionHref,
    });
    expect(table()).toHaveAttribute('aria-rowcount', '5');
  });

  it('does not use grouped aggregates of a scoped collection', async () => {
    const status = { href: '/api/v3/statuses/1' };
    await mount({
      workPackages: [{ id: '1', attributes: { status } }],
      pagination: { offset: 1, pageSize: 20, total: 1 },
      groups: [{ value: 'G', href: status.href, count: 1 }],
      collectionHref: '/api/v3/versions/3/work_packages',
    });
    harness.expectNoRowPositions();
  });

  it('does not use grouped aggregates while the baseline is active', async () => {
    const status = { href: '/api/v3/statuses/1' };
    await mount({
      workPackages: [{ id: '1', attributes: { status } }],
      pagination: { offset: 1, pageSize: 20, total: 1 },
      groups: [{ value: 'G', href: status.href, count: 1 }],
      baseline: true,
    });
    harness.expectNoRowPositions();
  });

  it('withdraws positions while the create section exposes two rows', async () => {
    await mount();
    (createRow().parentElement as HTMLTableSectionElement).insertRow().insertCell().textContent = 'Editing';
    harness.table.rowPositions!.paint();
    harness.expectNoRowPositions();
  });

  it('leaves attributes untouched when values are unchanged', async () => {
    await mount();
    const records:MutationRecord[] = [];
    const observer = new MutationObserver((batch) => records.push(...batch));
    observer.observe(table(), { subtree: true, attributes: true });
    harness.table.rowPositions!.paint();
    await nextTask();
    observer.disconnect();
    expect(records).toEqual([]);
  });

  it('keeps sibling metadata outside this projection', async () => {
    await mount();
    const row = harness.row('21');
    row.setAttribute('aria-posinset', '21');
    row.setAttribute('aria-setsize', '100');
    harness.table.rowPositions!.paint();
    expect(row).toHaveAttribute('aria-posinset', '21');
    expect(row).toHaveAttribute('aria-setsize', '100');
    expect(harness.totalsRow()).not.toHaveAttribute('aria-posinset');
  });

});
