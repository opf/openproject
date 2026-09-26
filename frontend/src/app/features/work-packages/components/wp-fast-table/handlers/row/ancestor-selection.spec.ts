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

import { usePlatform } from 'core-common/testing/platform';
import { TableEditForm } from 'core-app/features/work-packages/components/wp-edit-form/table-edit-form';
import { fireEvent, waitFor } from '@testing-library/dom';
import { WpTableHoverSync } from 'core-app/features/work-packages/components/wp-table/wp-table-hover-sync';
import { locateTableRowByIdentifier, rowId } from '../../helpers/wp-table-row-helpers';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('Ancestor row selection', () => {
  let harness:TableHarness;

  const pretendPlatform = usePlatform();

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '2', ancestors: [{ id: '1' }] }, { id: '3' }],
      showHierarchies: true,
      configuration: { contextMenuEnabled: true },
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  it('selects an ancestor and starts a range from it', () => {
    harness.click('1');
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(harness.row('1')).toHaveClass('-checked');

    harness.click('3', { shiftKey: true });
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3']);
  });

  it('selects the ancestor on right-click', () => {
    harness.click('3');
    fireEvent.contextMenu(harness.row('1'));
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(harness.row('1')).toHaveClass('-checked');
  });

  it.each([
    { platform: 'Linux', ctrlKey: true },
    { platform: 'MacIntel', metaKey: true },
  ])('anchors Select All on the ancestor on $platform', ({ platform, ...modifiers }) => {
    pretendPlatform(platform);
    expect(fireEvent.keyDown(harness.row('1'), { key: 'a', ...modifiers })).toBe(false);
    harness.click('2', { shiftKey: true });
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
  });

  it('leaves the hierarchy collapse control shortcut alone', () => {
    const control = harness.row('1').querySelector<HTMLElement>('a[role="button"]')!;
    expect(fireEvent.keyDown(control, { key: 'a', ctrlKey: true })).toBe(true);
    expect(harness.selection.isEmpty).toBe(true);
  });

  it('resolves the ancestor edit cell using the dataset identity', () => {
    const form = Object.assign(Object.create(TableEditForm.prototype) as TableEditForm, {
      table: harness.table,
      classIdentifier: harness.row('1').dataset.classIdentifier,
    });
    expect(form.findCell('subject')).toBe(harness.row('1').querySelector('td.subject'));
  });

  it('retains both lookup identities through a row refresh', () => {
    const row = harness.row('1');
    expect(row).toHaveAttribute('data-class-identifier', 'wp-ancestor-row-1');
    expect(row).toHaveClass('wp-row-1', 'wp-row-1-table', 'wp-ancestor-row-1', 'wp-ancestor-row-1-table');
    const root = harness.table.tableAndTimelineContainer;
    expect(locateTableRowByIdentifier('wp-ancestor-row-1', root)).toBe(row);
    expect(locateTableRowByIdentifier('wp-row-1', root)).toBe(row);
    expect(row).toHaveClass(rowId('1'));
    harness.click('1');
    const workPackage = harness.selection.getSelectedWorkPackages()[0];
    harness.table.refreshRows(workPackage);
    expect(harness.row('1')).toHaveAttribute('data-class-identifier', 'wp-ancestor-row-1');
    expect(harness.row('1')).toHaveClass('wp-row-1-table', 'wp-ancestor-row-1-table');
  });

  it('synchronizes hover with the ancestor timeline row', async () => {
    const wrapper = harness.table.tableAndTimelineContainer;
    const hover = new WpTableHoverSync(wrapper);
    const timeline = wrapper.querySelector<HTMLElement>('.wp-ancestor-row-1-timeline')!;
    expect(timeline).not.toBeNull();
    hover.activate();
    try {
      fireEvent.mouseMove(harness.row('1'));
      await waitFor(() => expect(timeline).toHaveClass('row-hovered'));
      fireEvent.mouseMove(timeline);
      await waitFor(() => expect(harness.row('1')).toHaveClass('row-hovered'));
    } finally {
      hover.deactivate();
    }
  });
});
