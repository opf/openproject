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
import { groupOccurrenceKey } from '../rendered-occurrence-ledger';
import { buildWorkPackage } from '../testing/work-package-fixture';

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
  const index = (row:Element) => row.getAttribute('aria-rowindex');
  const createRow = () => table().querySelector<HTMLTableRowElement>('tbody[wpInlineCreate] tr')!;
  const expectIndices = (rows:Element[], indices:string[]) => {
    expect(rows).toHaveLength(indices.length);
    rows.forEach((row, position) => expect(row).toHaveAttribute('aria-rowindex', indices[position]));
  };
  afterEach(() => harness?.destroy());

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

  it('does not infer a flat count for hierarchy mode', async () => {
    await mount({ showHierarchies: true });
    expect(table()).not.toHaveAttribute('aria-rowcount');
    expect(harness.row('21')).not.toHaveAttribute('aria-rowindex');
  });

  describe('in hierarchy mode', () => {
    const parent = { id: '1' };
    const child = { id: '2', ancestors: [parent] };
    const other = { id: '3' };
    const entries = {
      1: { position: 1, parent: null },
      2: { position: 2, parent: '1' },
      3: { position: 3, parent: null },
    };
    const mountHierarchy = (options:Partial<TableHarnessOptions> = {}) => mount({
      workPackages: [child, other, parent],
      showHierarchies: true,
      pagination: { offset: 1, pageSize: 20, total: 3 },
      rowPositions: { count: 3, entries },
      ...options,
    });

    it('publishes the positions the collection carries', async () => {
      await mountHierarchy();
      harness.expectRowPositions(['1', '2', '3', '4', '5', '6'], '6');
    });

    it('keeps query-wide positions of a later page, gaps included', async () => {
      await mountHierarchy({
        workPackages: [{ id: '5', ancestors: [parent] }],
        pagination: { offset: 2, pageSize: 1, total: 8 },
        rowPositions: { count: 9, entries: { 1: { position: 1, parent: null }, 5: { position: 7, parent: '1' } } },
      });
      harness.expectRowPositions(['1', '2', '8', '11', '12'], '12');
    });

    it('withdraws positions without row metadata', async () => {
      await mountHierarchy({ rowPositions: undefined });
      harness.expectNoRowPositions();
    });

    it('withdraws positions when a rendered parent disagrees with the collection', async () => {
      await mountHierarchy({ rowPositions: { count: 3, entries: { ...entries, 2: { position: 2, parent: null } } } });
      harness.expectNoRowPositions();
    });

    it('withdraws positions when a rendered row has no entry', async () => {
      await mountHierarchy({ rowPositions: { count: 3, entries: { 1: entries[1], 2: entries[2] } } });
      harness.expectNoRowPositions();
    });

    it('renders a reorder without a new collection in its new order and withdraws positions', async () => {
      await mountHierarchy();
      harness.table.initialSetup(['3', '1', '2'].map((id) => harness.table.originalRowIndex[id].object));
      await waitFor(() => expect(harness.rowIds()).toEqual(['3', '1', '2']));
      harness.expectNoRowPositions();
    });

    it('withdraws positions when a refreshed row moves to another parent', async () => {
      await mountHierarchy();
      harness.injector.get(States).workPackages.get('2').putValue(buildWorkPackage({ id: '2' }));
      await waitFor(() => harness.expectNoRowPositions());
    });

    it('withdraws positions when a refreshed row moves above its parent', async () => {
      await mountHierarchy();
      harness.injector.get(States).workPackages.get('2').putValue(buildWorkPackage({ id: '2', ancestors: [{ id: '4' }, parent] }));
      await nextTask();
      expect(harness.row('2').querySelector('.wp-table--hierarchy-span')).toHaveAttribute('data-indentation', '65px');
      harness.expectNoRowPositions();
    });

    it('keeps positions when a refreshed row keeps its parent', async () => {
      await mountHierarchy();
      harness.injector.get(States).workPackages.get('2').putValue(buildWorkPackage({ id: '2', ancestors: [parent] }));
      await nextTask();
      harness.expectRowPositions(['1', '2', '3', '4', '5', '6'], '6');
    });

    it('keeps positions and the count when a parent collapses', async () => {
      await mountHierarchy();
      harness.injector.get(WorkPackageViewHierarchiesService).collapse('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      expect(harness.row('2')).toHaveAttribute('aria-rowindex', '3');
      expect(harness.row('1')).toHaveAttribute('aria-rowindex', '2');
      expect(harness.row('3')).toHaveAttribute('aria-rowindex', '4');
      expect(table()).toHaveAttribute('aria-rowcount', '6');
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
      harness.table.rowPositions!.commit({ source: harness.querySpace.results.value!, body: { count: 100, ordinals } });
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
