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

import { Injector } from '@angular/core';
import { EMPTY } from 'rxjs';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { DragAndDropService, DragMember } from 'core-app/shared/helpers/drag-and-drop/drag-and-drop.service';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { DragAndDropTransformer } from './drag-and-drop-transformer';

describe('DragAndDropTransformer', () => {
  let harness:TableHarness;

  afterEach(() => harness?.destroy());

  it('anchors a following shift-click at the picked-up row when group headers precede it', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }] });
    await harness.render();
    harness.querySpace.tableRendered.putValue([
      { classIdentifier: 'group-header', workPackageId: null, hidden: false },
      ...harness.table.renderedRows,
    ]);
    const register = vi.fn<(member:DragMember) => void>();
    const injector = Injector.create({
      parent: harness.injector,
      providers: [
        { provide: DragAndDropService, useValue: { register, remove: vi.fn() } },
        { provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: EMPTY } },
      ],
    });
    new DragAndDropTransformer(injector, harness.table);
    harness.click('1');
    harness.click('3', { ctrlKey: true });

    register.mock.calls[0][0].onDragStarted!(harness.row('3'));
    harness.click('4', { shiftKey: true });

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3', '4']);
    expect(harness.row('2')).not.toHaveClass('-checked');
  });
});
