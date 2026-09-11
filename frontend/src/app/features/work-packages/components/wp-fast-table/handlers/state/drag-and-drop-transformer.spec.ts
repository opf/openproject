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

import { TestBed } from '@angular/core/testing';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { buildTable, TableHarness } from '../../testing/table-harness';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };
const groups = [
  { value: 'New', href: newStatus.href, count: 2 },
  { value: 'In progress', href: inProgressStatus.href, count: 2 },
];

interface DropSnapshot {
  group:string|null;
  previous:string|undefined;
  next:string|undefined;
}

describe('DragAndDropTransformer', () => {
  let harness:TableHarness;
  let drops:DropSnapshot[];
  let dropAction:() => Promise<unknown>;

  beforeEach(async () => {
    drops = [];
    dropAction = () => Promise.resolve();
    harness = buildTable({
      workPackages: [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: newStatus } },
        { id: '3', attributes: { status: inProgressStatus } },
        { id: '4', attributes: { status: inProgressStatus } },
      ],
      groups,
      dragAction: {
        handleDrop: (_workPackage, el) => {
          drops.push(snapshot(el));
          return dropAction();
        },
      },
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const rowIds = () => harness.rows().map((row) => row.dataset.workPackageId);

  function snapshot(el:HTMLElement):DropSnapshot {
    const header = harness.groupHeaderOf(el);
    return {
      group: header ? groups[Number(header.dataset.groupIndex)].value : null,
      previous: (el.previousElementSibling as HTMLElement|null)?.dataset.workPackageId,
      next: (el.nextElementSibling as HTMLElement|null)?.dataset.workPackageId,
    };
  }

  it('renders the groups with their header rows', () => {
    expect(rowIds()).toEqual(['1', '2', '3', '4']);
    expect(snapshot(harness.row('2'))).toEqual({ group: 'New', previous: '1', next: undefined });
    expect(snapshot(harness.row('3'))).toEqual({ group: 'In progress', previous: undefined, next: '4' });
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
    expect(snapshot(harness.row('1'))).toEqual({ group: 'New', previous: '2', next: undefined });
  });

  it('completes without a drop action when the order does not change', async () => {
    const success = await harness.drop('1', '1', 'bottom');

    expect(success).toBe(true);
    expect(drops).toEqual([]);
  });

  it('anchors a following shift-click at the picked-up row when group headers precede it', () => {
    harness.click('1');
    harness.click('3', { ctrlKey: true });

    harness.dragStart('3');
    harness.click('4', { shiftKey: true });

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3', '4']);
    expect(harness.row('2')).not.toHaveClass('-checked');
  });

  it('puts the row back and reports the error when the drop action fails', async () => {
    const error = new Error('drop failed');
    dropAction = () => Promise.reject(error);
    const notification = TestBed.inject(HalResourceNotificationService);
    const handleRawError = vi.spyOn(notification, 'handleRawError');

    const success = await harness.drop('1', '2', 'bottom');

    expect(success).toBe(false);
    expect(rowIds()).toEqual(['1', '2', '3', '4']);
    expect(snapshot(harness.row('1'))).toEqual({ group: 'New', previous: undefined, next: '2' });
    expect(handleRawError).toHaveBeenCalledExactlyOnceWith(error);
  });
});
