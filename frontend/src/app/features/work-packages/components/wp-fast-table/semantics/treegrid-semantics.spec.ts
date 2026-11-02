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

import { waitFor, within } from '@testing-library/dom';
import { firstValueFrom } from 'rxjs';
import { map, skip, take } from 'rxjs/operators';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { buildTable, TableHarness, TableHarnessOptions } from '../testing/table-harness';
import { WorkPackageFixture } from '../testing/work-package-fixture';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { navigableCellClassName } from '../handlers/state/keyboard/roving-tabindex';
import { groupOccurrenceKey, placeholderOccurrenceKey, relationOccurrenceKey, wpOccurrenceKey } from '../rendered-occurrence-ledger';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

const groupedFixtures:Pick<TableHarnessOptions, 'workPackages'|'groups'> = {
  workPackages: [
    { id: '1', attributes: { status: newStatus } },
    { id: '2', attributes: { status: newStatus } },
    { id: '3', attributes: { status: inProgressStatus } },
  ],
  groups: [
    { value: 'New', href: newStatus.href, count: 2, sums: { storyPoints: 5 } },
    { value: 'In progress', href: inProgressStatus.href, count: 1, sums: { storyPoints: 8 } },
  ],
};

const relationColumn = { id: 'relationsOfTypeFollows', relationType: 'follows' };
const parent:WorkPackageFixture = { id: '1' };
const child:WorkPackageFixture = { id: '2', ancestors: [parent] };

describe('TreegridSemantics', () => {
  let harness:TableHarness;

  const mount = (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      ...options,
      configuration: { keyboardNavigationEnabled: true, ...options.configuration },
    });
    return harness;
  };

  const element = (key:string) => harness.table.ledger.byKey(key)!.element!;
  const groupHeader = (index:number) => element(groupOccurrenceKey(index, 'header'));
  const sumsRow = (index:number) => element(groupOccurrenceKey(index, 'sums'));
  const groupIdentifier = (index:number) => harness.groupHeader(index).dataset.groupIdentifier!;
  const toggleGroup = (index:number) => harness.injector.get(WorkPackageViewCollapsedGroupsService)
    .toggleGroupCollapseState(groupIdentifier(index));
  const hierarchies = () => harness.injector.get(WorkPackageViewHierarchiesService);
  const resource = (id:string) => harness.injector.get(States).workPackages.get(id).value!;

  const atNextPublication = <T>(read:() => T):Promise<T> => firstValueFrom(
    harness.querySpace.tableRendered.values$().pipe(skip(1), take(1), map(read)),
  );

  const atNextRefresh = <T>(read:() => T):Promise<T> => firstValueFrom(
    harness.table.rowsRefreshed$.pipe(take(1), map(read)),
  );

  const expectHidden = (row:HTMLElement) => expect(row).toHaveAttribute('aria-hidden', 'true');
  const expectExposed = (row:HTMLElement) => expect(row).not.toHaveAttribute('aria-hidden');
  const expectCollapsed = (row:HTMLElement) => {
    expect(row).not.toBeVisible();
    expect(row).not.toHaveAttribute('aria-hidden');
  };
  const expectShown = (row:HTMLElement) => {
    expect(row).toBeVisible();
    expect(row).not.toHaveAttribute('aria-hidden');
  };

  afterEach(() => harness.destroy());

  it('paints rows, levels and cell roles after a full render', async () => {
    mount({
      ...groupedFixtures,
      baseline: true,
      configuration: { dragAndDropEnabled: true },
    });
    await harness.render();

    const nested = document.createElement('table');
    nested.innerHTML = '<tbody><tr><td>Editor</td></tr></tbody>';
    harness.row('1').lastElementChild!.append(nested);
    harness.table.setHidden(new Map([[wpOccurrenceKey('1'), false]]));

    expect(harness.row('1')).toHaveAttribute('role', 'row');
    expect(harness.row('1')).toHaveAttribute('aria-level', '2');
    expect(groupHeader(0)).toHaveAttribute('role', 'row');
    expect(groupHeader(0)).toHaveAttribute('aria-level', '1');
    expect(sumsRow(0)).toHaveAttribute('aria-level', '2');

    [harness.row('1'), groupHeader(0), sumsRow(0)].forEach((row) => {
      Array.from(row.cells).forEach((cell) => expect(cell).toHaveAttribute('role', 'gridcell'));
    });
    expect(harness.row('1').querySelector('.__internal-sorthandle')).toHaveAttribute('role', 'gridcell');
    expect(harness.row('1').querySelector('.op-table-baseline--column-cell')).toHaveAttribute('role', 'gridcell');
    expect(groupHeader(0).cells[0]).toHaveAttribute('colspan');
    expect(nested.querySelector('tr')).not.toHaveAttribute('role');
    expect(nested.querySelector('td')).not.toHaveAttribute('role');
  });

  it('exposes selection only on work package occurrences', async () => {
    mount({
      ...groupedFixtures,
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', relationColumn],
    });
    harness.expand('1', relationColumn.id);
    await harness.render();
    const relationRow = harness.relationRow('1', '2');

    harness.click('2');

    await waitFor(() => expect(harness.row('2')).toHaveAttribute('aria-selected', 'true'));
    expect(relationRow).toHaveAttribute('aria-selected', 'true');
    expect(harness.row('1')).toHaveAttribute('aria-selected', 'false');
    expect(harness.row('3')).toHaveAttribute('aria-selected', 'false');
    [groupHeader(0), groupHeader(1), sumsRow(0), sumsRow(1)]
      .forEach((row) => expect(row).not.toHaveAttribute('aria-selected'));

    harness.selection.reset();

    await waitFor(() => expect(harness.row('2')).toHaveAttribute('aria-selected', 'false'));
    expect(relationRow).toHaveAttribute('aria-selected', 'false');
  });

  it('exposes expansion on groups only', async () => {
    mount(groupedFixtures);
    await harness.render();

    expect(groupHeader(0)).toHaveAttribute('aria-expanded', 'true');
    [harness.row('1'), sumsRow(0)].forEach((row) => expect(row).not.toHaveAttribute('aria-expanded'));

    toggleGroup(0);
    await waitFor(() => expect(groupHeader(0)).toHaveAttribute('aria-expanded', 'false'));
    expect(groupHeader(1)).toHaveAttribute('aria-expanded', 'true');

    toggleGroup(0);
    await waitFor(() => expect(groupHeader(0)).toHaveAttribute('aria-expanded', 'true'));
  });

  it('exposes expansion on hierarchy parents only', async () => {
    mount({
      workPackages: [parent, child, { id: '3' }],
      relations: [{ from: '1', to: '3', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', relationColumn],
      showHierarchies: true,
    });
    harness.expand('1', relationColumn.id);
    await harness.render();

    expect(harness.row('1')).toHaveAttribute('aria-expanded', 'true');
    [harness.row('2'), harness.row('3'), harness.relationRow('1', '3')]
      .forEach((row) => expect(row).not.toHaveAttribute('aria-expanded'));

    hierarchies().toggle('1');
    await waitFor(() => expect(harness.row('1')).toHaveAttribute('aria-expanded', 'false'));

    hierarchies().toggle('1');
    await waitFor(() => expect(harness.row('1')).toHaveAttribute('aria-expanded', 'true'));
  });

  it('hides collapsed occurrences before publication', async () => {
    mount({
      ...groupedFixtures,
      relations: [{ from: '1', to: '3', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', relationColumn],
    });
    harness.expand('1', relationColumn.id);
    await harness.render();
    harness.click('1');
    const relationKey = relationOccurrenceKey('ofType', '1', '3');
    const groupMembers = () => [harness.row('1'), harness.row('2'), element(relationKey), sumsRow(0)];
    const exposure = () => groupMembers().map((row) => [getComputedStyle(row).display, row.getAttribute('aria-hidden')]);

    const collapsed = atNextPublication(exposure);
    toggleGroup(0);
    expect(await collapsed).toEqual(Array(4).fill(['none', null]));
    expectShown(groupHeader(0));
    expectShown(harness.row('3'));
    expectShown(sumsRow(1));
    expect(harness.selection.isSelected('1')).toBe(true);
    expect(harness.row('1')).toHaveAttribute('aria-selected', 'true');

    const expanded = atNextPublication(exposure);
    toggleGroup(0);
    expect(await expanded).toEqual(Array(4).fill(['table-row', null]));
    expect(harness.selection.isSelected('1')).toBe(true);
  });

  it('repaints replacement group headers with an empty visibility map', async () => {
    mount(groupedFixtures);
    await harness.render();
    const headerKey = groupOccurrenceKey(0, 'header');
    const header = groupHeader(0);
    const headerOnly = harness.table.ledger.beginRender();
    headerOnly.append({ ...harness.table.ledger.byKey(headerKey)!, additionalClasses: [], workPackage: null });
    harness.tbody.replaceChildren(header);
    harness.table.ledger.commit(headerOnly);
    header.removeAttribute('role');
    header.removeAttribute('aria-level');
    header.removeAttribute('aria-expanded');

    const replaced = atNextPublication(() => {
      const current = groupHeader(0);
      return {
        size: harness.table.ledger.size,
        replaced: current !== header,
        role: current.getAttribute('role'),
        level: current.getAttribute('aria-level'),
        expanded: current.getAttribute('aria-expanded'),
      };
    });
    toggleGroup(0);

    expect(await replaced).toEqual({
      size: 1, replaced: true, role: 'row', level: '1', expanded: 'false',
    });
  });

  it('paints initially collapsed groups', async () => {
    mount(groupedFixtures);
    harness.querySpace.collapsedGroups.putValue({ [harness.querySpace.groups.value![0].identifier]: true });
    await harness.render();

    expect(groupHeader(0)).toHaveAttribute('aria-expanded', 'false');
    expectCollapsed(harness.row('1'));
    expectCollapsed(sumsRow(0));
    expectShown(harness.row('3'));
  });

  it('paints initially collapsed hierarchy structures', async () => {
    mount({
      workPackages: [parent, child, { id: '3', ancestors: [parent, child] }, { id: '4' }],
      showHierarchies: true,
    });
    hierarchies().collapse('2');
    hierarchies().collapse('1');
    await harness.render();

    expect(harness.row('1')).toHaveAttribute('aria-expanded', 'false');
    expectCollapsed(harness.row('2'));
    expectCollapsed(harness.row('3'));
    expectShown(harness.row('4'));

    hierarchies().expand('1');

    await waitFor(() => expectShown(harness.row('2')));
    expect(harness.row('1')).toHaveAttribute('aria-expanded', 'true');
    expect(harness.row('2')).toHaveAttribute('aria-expanded', 'false');
    expect(harness.row('2')).toHaveAttribute('aria-level', '2');
    expectCollapsed(harness.row('3'));
    expect(harness.row('3')).toHaveAttribute('aria-level', '3');
  });

  it('stops painting after teardown', async () => {
    mount(groupedFixtures);
    await harness.render();
    const row = harness.row('1');
    const workPackage = resource('1');
    expect(row).toHaveAttribute('aria-selected', 'false');

    harness.table.redrawTable();
    expect(harness.table.hasPendingRender).toBe(true);
    harness.table.destroy();
    await new Promise((resolve) => { requestAnimationFrame(resolve); });
    row.removeAttribute('aria-level');
    harness.selection.replaceSelection('1');
    const before = harness.tbody.outerHTML;

    harness.table.refreshRows(workPackage);
    const semantics = harness.table.semantics!;
    semantics.paint();
    semantics.paintWorkPackage('1');
    semantics.paintSelection();

    expect(row).not.toHaveAttribute('aria-level');
    expect(row).toHaveAttribute('aria-selected', 'false');
    expect(harness.tbody.outerHTML).toBe(before);
  });

  it('keeps hidden state and level when a hidden occurrence refreshes', async () => {
    mount(groupedFixtures);
    await harness.render();
    toggleGroup(0);
    await waitFor(() => expectCollapsed(harness.row('1')));
    const previousCells = Array.from(harness.row('1').cells);

    const refreshed = atNextRefresh(() => {
      const row = harness.row('1');
      const cells = Array.from(row.cells);
      return {
        rebuiltCells: cells.some((cell) => !previousCells.includes(cell)),
        cellRoles: cells.every((cell) => cell.getAttribute('role') === 'gridcell'),
        hidden: row.getAttribute('aria-hidden'),
        display: getComputedStyle(row).display,
        level: row.getAttribute('aria-level'),
        role: row.getAttribute('role'),
        selected: row.getAttribute('aria-selected'),
      };
    });
    harness.table.refreshRows(resource('1'));

    expect(await refreshed).toEqual({
      rebuiltCells: true, cellRoles: true, hidden: null, display: 'none', level: '2', role: 'row', selected: 'false',
    });
  });

  it('hides the results rowgroup when it holds only the drag placeholder', async () => {
    mount({ workPackages: [], configuration: { dragAndDropEnabled: true } });
    await harness.render();

    expectHidden(element(placeholderOccurrenceKey()));
    ['role', 'aria-level', 'aria-selected', 'aria-expanded']
      .forEach((name) => expect(element(placeholderOccurrenceKey())).not.toHaveAttribute(name));
    expect(harness.tbody).toHaveAttribute('role', 'rowgroup');
    expectHidden(harness.tbody);

    await harness.render([{ id: '1' }]);
    expectExposed(harness.tbody);
    expect(within(harness.tbody).getAllByRole('row')).toEqual([harness.row('1')]);

    await harness.render([]);
    expectHidden(harness.tbody);
  });

  it.each<[string, Partial<TableHarnessOptions>]>([
    ['expansion', { workPackages: [parent, child], showHierarchies: true }],
    ['placeholder and section visibility', { workPackages: [], configuration: { dragAndDropEnabled: true } }],
  ])('leaves unchanged %s untouched when repainting', async (_, options) => {
    mount(options);
    await harness.render();
    const observer = new MutationObserver(() => undefined);
    observer.observe(harness.tbody, { subtree: true, attributes: true, attributeFilter: ['aria-expanded', 'aria-hidden'] });
    harness.table.semantics!.paint();
    const records = observer.takeRecords();
    observer.disconnect();
    expect(records).toEqual([]);
  });

  it('pins relation rows of a collapsed hierarchy parent', async () => {
    mount({
      workPackages: [parent, child, { id: '3' }],
      relations: [{ from: '1', to: '3', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', relationColumn],
      showHierarchies: true,
    });
    harness.expand('1', relationColumn.id);
    await harness.render();

    hierarchies().collapse('1');

    await waitFor(() => expect(harness.row('1')).toHaveAttribute('aria-expanded', 'false'));
    expectShown(harness.relationRow('1', '3'));
    expect(harness.relationRow('1', '3')).toHaveAttribute('aria-level', '2');
    expectCollapsed(harness.row('2'));
  });

  it('keeps the cell role on drag handles that replace the first cell', async () => {
    let resolvePositions:(positions:QueryOrder) => void = () => undefined;
    mount({ configuration: { dragAndDropEnabled: true } });
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'positionsFor')
      .mockReturnValue(new Promise<QueryOrder>((resolve) => { resolvePositions = resolve; }));
    await harness.render();
    const placeholderCell = harness.row('1').cells[0];

    resolvePositions({ 1: 0, 2: 1, 3: 2 });

    await waitFor(() => expect(harness.row('1').cells[0]).not.toBe(placeholderCell));
    expect(harness.row('1').cells[0]).toHaveClass('wp-table--sort-td');
    expect(harness.row('1').cells[0]).toHaveAttribute('role', 'gridcell');
    expect(harness.row('1').cells[0]).not.toHaveClass(navigableCellClassName);
  });

  describe('when a collapse lands on a queued render', () => {
    const queueRedraw = () => {
      const frames:(() => void)[] = [];
      vi.spyOn(harness.table.uiWork, 'frame').mockImplementation((callback) => { frames.push(callback); });
      harness.table.redrawTable();
      return () => frames.splice(0).forEach((callback) => callback());
    };

    const collapseState = (parentRow:() => HTMLElement, childId:string, before:HTMLElement) => () => ({
      committed: harness.row(childId) !== before,
      expanded: parentRow().getAttribute('aria-expanded'),
      hidden: harness.row(childId).getAttribute('aria-hidden'),
      ledgerHidden: harness.table.ledger.byWorkPackageId(childId)[0].hidden,
      display: getComputedStyle(harness.row(childId)).display,
    });

    const collapsed = {
      committed: true, expanded: 'false', hidden: null, ledgerHidden: true, display: 'none',
    };

    const raced = {
      committed: true, expanded: null, hidden: null, ledgerHidden: false, display: 'table-row',
    };

    const releaseAfter = async <T>(state:() => T, collapse:() => void, release:() => void) => {
      collapse();
      const published = atNextPublication(state);
      release();
      return { published: await published, final: state() };
    };

    it('publishes a collapsed group with its rows hidden', async () => {
      mount(groupedFixtures);
      await harness.render();
      const state = collapseState(() => groupHeader(0), '1', harness.row('1'));

      expect(await releaseAfter(state, () => toggleGroup(0), queueRedraw())).toEqual({ published: collapsed, final: collapsed });
    });

    it('publishes a collapsed hierarchy parent with its children hidden', async () => {
      mount({ workPackages: [parent, child], showHierarchies: true });
      await harness.render();
      const state = collapseState(() => harness.row('1'), '2', harness.row('2'));

      expect(await releaseAfter(state, () => hierarchies().collapse('1'), queueRedraw())).toEqual({ published: collapsed, final: collapsed });
    });

    it('keeps the capability-off group race unchanged', async () => {
      mount({ ...groupedFixtures, configuration: { keyboardNavigationEnabled: false } });
      await harness.render();
      const state = collapseState(() => groupHeader(0), '1', harness.row('1'));

      expect(await releaseAfter(state, () => toggleGroup(0), queueRedraw())).toEqual({ published: raced, final: raced });
    });

    it('keeps the capability-off hierarchy race unchanged', async () => {
      mount({ workPackages: [parent, child], showHierarchies: true, configuration: { keyboardNavigationEnabled: false } });
      await harness.render();
      const state = collapseState(() => harness.row('1'), '2', harness.row('2'));

      expect(await releaseAfter(state, () => hierarchies().collapse('1'), queueRedraw())).toEqual({ published: raced, final: raced });
    });
  });

  it('leaves capability-off tables untouched', async () => {
    harness = buildTable({ ...groupedFixtures, configuration: { dragAndDropEnabled: true } });
    await harness.render();
    harness.click('1');
    toggleGroup(0);
    await waitFor(() => expect(harness.row('1')).not.toBeVisible());

    expect(harness.table.semantics).toBeNull();
    const rows = Array.from(harness.tbody.rows);
    [harness.tbody, ...rows, ...rows.flatMap((row) => Array.from(row.cells))].forEach((node) => {
      ['role', 'aria-level', 'aria-selected', 'aria-expanded', 'aria-hidden']
        .forEach((name) => expect(node).not.toHaveAttribute(name));
    });
  });
});
