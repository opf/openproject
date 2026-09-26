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

import { fireEvent } from '@testing-library/dom';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('Context menu entry', () => {
  let harness:TableHarness;
  let menuTargets:string[][];
  let opened:ReturnType<typeof vi.spyOn>;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      configuration: { contextMenuEnabled: true },
    });
    await harness.render();

    menuTargets = [];
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockImplementation((workPackages:WorkPackageResource[]) => {
        menuTargets.push(workPackages.map((wp) => wp.id!));
        return [];
      });
    opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
  });

  afterEach(() => harness.destroy());

  it('selects an unselected row and opens the menu for it alone', () => {
    harness.click('2');

    expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(harness.focus.focusedWorkPackage).toBe('2');
    expect(opened).toHaveBeenCalledTimes(1);
    expect(menuTargets).toEqual([['1']]);
  });

  it('keeps a batch selection and opens the menu for the whole batch', () => {
    harness.click('1');
    harness.click('2', { shiftKey: true });

    fireEvent.contextMenu(harness.row('2'));

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
    expect(opened).toHaveBeenCalledTimes(1);
    expect(menuTargets).toEqual([['1', '2']]);
  });

  it('opens the menu from the keyboard without changing the selection', () => {
    harness.click('2');

    expect(fireEvent.keyDown(harness.row('1'), { key: 'F10', shiftKey: true, altKey: true })).toBe(false);

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
    expect(opened).toHaveBeenCalledTimes(1);
  });
});
