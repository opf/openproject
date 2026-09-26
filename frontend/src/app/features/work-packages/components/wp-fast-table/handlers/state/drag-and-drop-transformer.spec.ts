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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { buildTable, TableHarness, TableHarnessOptions } from '../../testing/table-harness';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };
const groups = [
  { value: 'New', href: newStatus.href, count: 2 },
  { value: 'In progress', href: inProgressStatus.href, count: 2 },
];

const groupedWorkPackages = [
  { id: '1', attributes: { status: newStatus } },
  { id: '2', attributes: { status: newStatus } },
  { id: '3', attributes: { status: inProgressStatus } },
  { id: '4', attributes: { status: inProgressStatus } },
];

interface DropSnapshot {
  group:string|null;
  previous:string|undefined;
  next:string|undefined;
}

function snapshot(table:TableHarness, el:HTMLElement):DropSnapshot {
  const header = table.groupHeaderOf(el);
  return {
    group: header ? groups[Number(header.dataset.groupIndex)].value : null,
    previous: (el.previousElementSibling as HTMLElement|null)?.dataset.workPackageId,
    next: (el.nextElementSibling as HTMLElement|null)?.dataset.workPackageId,
  };
}

describe('DragAndDropTransformer', () => {
  let harness:TableHarness;
  let drops:DropSnapshot[];
  let dropAction:() => Promise<unknown>;

  beforeEach(async () => {
    drops = [];
    dropAction = () => Promise.resolve();
    harness = buildTable({
      workPackages: groupedWorkPackages,
      groups,
      dragAction: {
        handleDrop: (_workPackage, el) => {
          drops.push(snapshot(harness, el));
          return dropAction();
        },
      },
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const rowIds = () => harness.rows().map((row) => row.dataset.workPackageId);

  it('renders the groups with their header rows', () => {
    expect(rowIds()).toEqual(['1', '2', '3', '4']);
    expect(snapshot(harness, harness.row('2'))).toEqual({ group: 'New', previous: '1', next: undefined });
    expect(snapshot(harness, harness.row('3'))).toEqual({ group: 'In progress', previous: undefined, next: '4' });
  });

  it('keeps a bottom-edge drop on the last row of a group inside that group', async () => {
    const success = await harness.drop('1', '2', 'bottom');

    expect(success).toBe(true);
    expect(drops).toEqual([{ group: 'New', previous: '2', next: undefined }]);
  });

  it('moves a top-edge drop on the first row of a group into that group', async () => {
    await harness.drop('1', '3', 'top');

    expect(drops).toEqual([{ group: 'In progress', previous: undefined, next: '3' }]);
  });

  it('appends a drop past the last row to the last group', async () => {
    await harness.drop('1', null, null);

    expect(drops).toEqual([{ group: 'In progress', previous: '4', next: undefined }]);
  });

  it('rebuilds the table from the persisted order', async () => {
    await harness.drop('1', '2', 'bottom');
    await harness.nextRender();

    expect(rowIds()).toEqual(['2', '1', '3', '4']);
    expect(snapshot(harness, harness.row('1'))).toEqual({ group: 'New', previous: '2', next: undefined });
  });

  it('completes without a drop action when the order does not change', async () => {
    const success = await harness.drop('1', '1', 'bottom');

    expect(success).toBe(true);
    expect(drops).toEqual([]);
  });

  it('anchors a following shift-click at the picked-up row when group headers precede it', async () => {
    harness.click('1');
    harness.click('3', { ctrlKey: true });

    harness.dragStart('3');
    await harness.drop('3', '3', 'bottom');
    harness.click('4', { shiftKey: true });

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3', '4']);
    expect(harness.row('2')).not.toHaveClass('-checked');
  });

  it('puts the row back and reports the error when the drop action fails', async () => {
    const error = new Error('drop failed');
    dropAction = () => Promise.reject(error);
    const notification = harness.injector.get(HalResourceNotificationService);
    const handleRawError = vi.spyOn(notification, 'handleRawError');

    const success = await harness.drop('1', '2', 'bottom');

    expect(success).toBe(false);
    expect(rowIds()).toEqual(['1', '2', '3', '4']);
    expect(snapshot(harness, harness.row('1'))).toEqual({ group: 'New', previous: undefined, next: '2' });
    expect(handleRawError).toHaveBeenCalledExactlyOnceWith(error);
  });
});

describe('DragAndDropTransformer with two tables showing the same work packages', () => {
  const parent = { id: '1' };
  const hierarchy = {
    parent,
    first: { id: '2', ancestors: [parent] },
    last: { id: '3', ancestors: [parent] },
    unrelated: { id: '4' },
  };
  const harnesses:TableHarness[] = [];
  let states:States;
  let dropped:HTMLElement[];
  let drops:DropSnapshot[];

  const mount = async (options:TableHarnessOptions) => {
    const table = buildTable({ ...options, states });
    harnesses.push(table);
    await table.render();
    return table;
  };

  const mountDragging = async (options:TableHarnessOptions) => {
    const table:TableHarness = await mount({
      ...options,
      dragAction: {
        handleDrop: (_workPackage, el) => {
          dropped.push(el);
          drops.push(snapshot(table, el));
          return Promise.resolve();
        },
      },
    });
    return table;
  };

  beforeEach(() => {
    states = new States();
    dropped = [];
    drops = [];
  });

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('moves and hands over the dragging table\'s own row', async () => {
    const other = await mount({ workPackages: [{ id: '4' }, { id: '3' }, { id: '2' }, { id: '1' }] });
    const dragging = await mountDragging({ workPackages: groupedWorkPackages, groups });
    const source = dragging.row('1');

    const success = await dragging.drop('1', '3', 'top');

    expect(success).toBe(true);
    expect(dropped).toHaveLength(1);
    expect(dropped[0]).toBe(source);
    expect(drops).toEqual([{ group: 'In progress', previous: undefined, next: '3' }]);
    expect(other.rowIds()).toEqual(['4', '3', '2', '1']);
  });

  it('redirects a drop onto a hierarchy collapsed only in the dragging table', async () => {
    const other = await mount({
      workPackages: [hierarchy.parent, hierarchy.first, hierarchy.last, hierarchy.unrelated],
      showHierarchies: true,
    });
    const dragging = await mountDragging({
      workPackages: [hierarchy.unrelated, hierarchy.parent, hierarchy.first, hierarchy.last],
      showHierarchies: true,
    });
    expect(dragging.rowIds()).toEqual(['4', '1', '2', '3']);
    fireEvent.click(within(dragging.row('1')).getByRole('button'));
    await waitFor(() => expect(dragging.row('2')).not.toBeVisible());

    const success = await dragging.drop('4', '2', 'top');

    expect(success).toBe(true);
    expect(drops).toEqual([{ group: null, previous: '3', next: undefined }]);
    expect(other.row('2')).toBeVisible();
  });
});
