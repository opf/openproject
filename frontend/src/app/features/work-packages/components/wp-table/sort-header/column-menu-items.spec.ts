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

import { Injector } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QUERY_SORT_BY_DESC, QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { buildTable, TableHarness } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { ColumnMenuHost, ColumnMenuItems } from './column-menu-items';

describe('ColumnMenuItems', () => {
  let harness:TableHarness;
  let builder:ColumnMenuItems;
  let calls:string[];
  let host:ColumnMenuHost;
  let followColumn:ReturnType<typeof vi.fn<ColumnMenuHost['followColumn']>>;
  let confirm:ReturnType<typeof vi.fn<ConfirmDialogService['confirm']>>;
  let showModal:ReturnType<typeof vi.fn<OpModalService['show']>>;

  const columns = () => harness.injector.get(WorkPackageViewColumnsService);
  const sortBy = () => harness.injector.get(WorkPackageViewSortByService);
  const groupBy = () => harness.injector.get(WorkPackageViewGroupByService);
  const hierarchies = () => harness.injector.get(WorkPackageViewHierarchiesService);

  const column = (id:string) => columns().getColumns().find((candidate) => candidate.id === id)!;
  const header = (id:string) => harness.headerCells()[columns().getColumns().findIndex((candidate) => candidate.id === id)];
  const build = (id:string) => builder.build(column(id), harness.table, header(id), host);
  const find = (items:OpContextMenuItem[], name:string) => items.find((item) => item.linkText === name)!;
  const click = (item:OpContextMenuItem) => item.onClick!(new MouseEvent('click'));
  const criterion = (id:string, direction:string) => ({ column: { href: column(id).href }, direction: { href: direction } }) as QuerySortByResource;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [],
      columns: ['id', 'subject', 'status'],
      productionMarkup: true,
      configuration: { columnMenuEnabled: true },
    });
    await harness.render();

    calls = [];
    followColumn = vi.fn<ColumnMenuHost['followColumn']>(() => { calls.push('followColumn'); });
    host = {
      close: vi.fn(() => { calls.push('close'); }),
      followColumn,
      returnFocus: vi.fn(() => { calls.push('returnFocus'); }),
    };
    confirm = vi.fn<ConfirmDialogService['confirm']>(() => { calls.push('confirm'); return Promise.resolve(); });
    showModal = vi.fn<OpModalService['show']>(() => { calls.push('showModal'); return undefined as never; });

    builder = Injector.create({
      providers: [
        ColumnMenuItems,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpModalService, useValue: { show: showModal } },
        { provide: ConfirmDialogService, useValue: { confirm } },
      ],
      parent: harness.injector,
    }).get(ColumnMenuItems);
  });

  afterEach(async () => {
    await harness.destroy();
  });

  it('hides sort and group items for an ineligible column', () => {
    vi.spyOn(sortBy(), 'isSortable').mockReturnValue(false);
    vi.spyOn(groupBy(), 'isGroupable').mockReturnValue(false);

    const items = build('id');

    expect(find(items, 'js.work_packages.query.sort_descending').hidden).toBe(true);
    expect(find(items, 'js.work_packages.query.sort_ascending').hidden).toBe(true);
    expect(find(items, 'js.work_packages.query.group_by_column').hidden).toBe(true);
  });

  it('hides move left on the first and move right on the last column', () => {
    expect(find(build('id'), 'js.work_packages.query.move_column_left').hidden).toBe(true);
    expect(find(build('id'), 'js.work_packages.query.move_column_right').hidden).toBe(false);
    expect(find(build('status'), 'js.work_packages.query.move_column_right').hidden).toBe(true);
    expect(find(build('status'), 'js.work_packages.query.move_column_left').hidden).toBe(false);
  });

  it('offers the hierarchy checkbox only on the subject column, checked when enabled', () => {
    hierarchies().setEnabled(true);

    const item = find(build('subject'), 'js.toolbar.settings.display_hierarchy');

    expect(item.checked).toBe(true);
    expect(item.hidden).toBe(false);
    expect(item.octicon).toBe('op-hierarchy');
    expect(find(build('status'), 'js.toolbar.settings.display_hierarchy').hidden).toBe(true);
  });

  it('offers Group by as a checked item while grouped by the column', () => {
    vi.spyOn(groupBy(), 'isGroupable').mockReturnValue(true);
    vi.spyOn(groupBy(), 'isCurrentlyGroupedBy').mockImplementation((candidate) => candidate.id === 'status');

    const grouped = find(build('status'), 'js.work_packages.query.group_by_column');
    const other = find(build('id'), 'js.work_packages.query.group_by_column');

    expect(grouped.checked).toBe(true);
    expect(grouped.hidden).toBe(false);
    expect(other.checked).toBe(false);
  });

  it('ungroups when the checked Group by item is activated', () => {
    vi.spyOn(groupBy(), 'isCurrentlyGroupedBy').mockReturnValue(true);
    const disable = vi.spyOn(groupBy(), 'disable').mockImplementation(() => undefined);
    const setBy = vi.spyOn(groupBy(), 'setBy').mockImplementation(() => undefined);

    expect(click(find(build('status'), 'js.work_packages.query.group_by_column'))).toBe(true);

    expect(disable).toHaveBeenCalledTimes(1);
    expect(setBy).not.toHaveBeenCalled();
  });

  it('separates sorting, grouping and column actions with dividers', () => {
    vi.spyOn(sortBy(), 'isSortable').mockReturnValue(true);
    vi.spyOn(groupBy(), 'isGroupable').mockReturnValue(true);

    const shape = build('subject').filter((item) => !item.hidden).map((item) => (item.divider ? '|' : item.linkText));

    expect(shape).toEqual([
      'js.work_packages.query.sort_descending',
      'js.work_packages.query.sort_ascending',
      '|',
      'js.work_packages.query.group_by_column',
      'js.toolbar.settings.display_hierarchy',
      '|',
      'js.work_packages.query.move_column_left',
      'js.work_packages.query.move_column_right',
      'js.work_packages.query.add_columns',
      'js.work_packages.query.remove_column',
    ]);
  });

  it('disables the hierarchy item while grouped', () => {
    vi.spyOn(groupBy(), 'isEnabled', 'get').mockReturnValue(true);

    expect(find(build('subject'), 'js.toolbar.settings.display_hierarchy').disabled).toBe(true);
  });

  it('toggles hierarchy mode and reports the activation', () => {
    hierarchies().setEnabled(false);

    expect(click(find(build('subject'), 'js.toolbar.settings.display_hierarchy'))).toBe(true);

    expect(hierarchies().isEnabled).toBe(true);
  });

  it('checks the sort item matching the primary sort criterion', () => {
    vi.spyOn(sortBy(), 'isSortable').mockReturnValue(true);
    vi.spyOn(sortBy(), 'current', 'get').mockReturnValue([criterion('status', QUERY_SORT_BY_DESC)]);

    const sorted = build('status');
    const other = build('subject');

    expect(find(sorted, 'js.work_packages.query.sort_descending')).toMatchObject({ checked: true, radio: true });
    expect(find(sorted, 'js.work_packages.query.sort_ascending')).toMatchObject({ checked: false, radio: true });
    expect(find(other, 'js.work_packages.query.sort_descending').checked).toBe(false);
  });

  it('leaves the sorting untouched when the checked sort item is activated', () => {
    vi.spyOn(sortBy(), 'isSortable').mockReturnValue(true);
    vi.spyOn(sortBy(), 'current', 'get').mockReturnValue([criterion('status', QUERY_SORT_BY_DESC)]);
    const add = vi.spyOn(sortBy(), 'addSortCriteria').mockImplementation(() => undefined);

    expect(click(find(build('status'), 'js.work_packages.query.sort_descending'))).toBe(true);

    expect(add).not.toHaveBeenCalled();
  });

  it('closes the menu before confirming a sort in manual mode', async () => {
    vi.spyOn(sortBy(), 'isManualSortingMode', 'get').mockReturnValue(true);
    vi.spyOn(sortBy(), 'isSortable').mockReturnValue(true);
    const sort = vi.spyOn(sortBy(), 'setAsSingleSortCriteria').mockImplementation(() => undefined);

    expect(click(find(build('subject'), 'js.work_packages.query.sort_descending'))).toBe(false);

    expect(calls).toEqual(['close', 'confirm']);
    await vi.waitFor(() => expect(sort).toHaveBeenCalledTimes(1));
  });

  it('sorts directly outside manual mode and reports the activation', () => {
    vi.spyOn(sortBy(), 'isSortable').mockReturnValue(true);
    const add = vi.spyOn(sortBy(), 'addSortCriteria').mockImplementation(() => undefined);

    expect(click(find(build('subject'), 'js.work_packages.query.sort_ascending'))).toBe(true);

    expect(add).toHaveBeenCalledTimes(1);
    expect(calls).toEqual([]);
  });

  it('closes the menu, follows the neighbor and returns focus when hiding a column', () => {
    const remove = vi.spyOn(columns(), 'removeColumn').mockImplementation(() => { calls.push('removeColumn'); });

    expect(click(find(build('subject'), 'js.work_packages.query.remove_column'))).toBe(false);

    expect(calls).toEqual(['close', 'removeColumn', 'followColumn', 'returnFocus']);
    expect(remove).toHaveBeenCalledWith(column('subject'));
    expect(followColumn).toHaveBeenCalledWith(header('id'));
  });

  it('follows the next header when hiding the first column', () => {
    vi.spyOn(columns(), 'removeColumn').mockImplementation(() => undefined);

    click(find(build('id'), 'js.work_packages.query.remove_column'));

    expect(followColumn).toHaveBeenCalledWith(header('subject'));
  });

  it('closes the menu before opening the columns dialog', () => {
    expect(click(find(build('subject'), 'js.work_packages.query.add_columns'))).toBe(false);

    expect(calls).toEqual(['close', 'showModal']);
    expect(showModal).toHaveBeenCalledWith(expect.any(Function), expect.anything(), { initialTab: 'columns' });
  });

  it('closes the menu before moving the column and follows it', () => {
    const shift = vi.spyOn(columns(), 'shift').mockImplementation(() => { calls.push('shift'); });

    expect(click(find(build('id'), 'js.work_packages.query.move_column_right'))).toBe(false);

    expect(shift).toHaveBeenCalledWith(column('id'), 1);
    expect(followColumn).toHaveBeenCalledWith(header('id'));
    expect(calls).toEqual(['close', 'shift', 'followColumn', 'returnFocus']);
  });
});
