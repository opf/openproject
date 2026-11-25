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

import { waitFor } from '@testing-library/dom';
import { WorkPackageViewOrderService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-order.service';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('DragDropHandleBuilder', () => {
  let harness:TableHarness;

  const renderHandle = async () => {
    harness = buildTable({ workPackages: [{ id: '1' }], configuration: { dragAndDropEnabled: true } });
    vi.spyOn(harness.injector.get(WorkPackageViewOrderService), 'positionsFor').mockResolvedValue({ 1: 0 });
    await harness.render();
    return waitFor(() => {
      const handle = harness.row('1').querySelector<HTMLElement>('.wp-table--drag-and-drop-handle');
      if (!handle) throw new Error('Drag handle not rendered yet');
      return handle;
    });
  };

  afterEach(async () => {
    await harness.destroy();
  });

  it('renders the Primer drag handle with the grabber icon', async () => {
    const handle = await renderHandle();

    expect(handle).toHaveClass('DragHandle');
    expect(handle.querySelector('svg.octicon')).not.toBeNull();
  });

  it('keeps the handle out of the accessibility tree and the tab order', async () => {
    const handle = await renderHandle();

    expect(handle).toHaveAttribute('aria-hidden', 'true');
    expect(handle).not.toHaveAttribute('role');
    expect(handle).not.toHaveAttribute('tabindex');
  });

  it('offers a 24 px pointer target with a grab cursor', async () => {
    const handle = await renderHandle();
    const { width, height } = handle.getBoundingClientRect();

    expect(width).toBeGreaterThanOrEqual(24);
    expect(height).toBeGreaterThanOrEqual(24);
    expect(getComputedStyle(handle).cursor).toBe('grab');
  });

  it('lets a pointer on the icon land on the handle', async () => {
    const handle = await renderHandle();

    expect(handle.querySelector('svg')).toHaveStyle({ pointerEvents: 'none' });
  });
});
