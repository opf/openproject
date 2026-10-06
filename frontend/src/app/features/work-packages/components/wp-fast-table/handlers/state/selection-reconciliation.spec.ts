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

import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { usePlatform } from 'core-common/testing/platform';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { buildWorkPackage } from '../../testing/work-package-fixture';

describe('Selection reconciliation with the rendered scope', () => {
  usePlatform('Linux');
  let harness:TableHarness;

  afterEach(() => harness?.destroy());

  describe('across the table lifecycle', () => {
    it('ignores a predecessor snapshot until its own first commit', async () => {
      const predecessor = [{ classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false }];
      harness = buildTable({
        workPackages: [{ id: '2', ancestors: [{ id: '1' }] }, { id: '3' }],
        showHierarchies: true,
        beforeAttach: (injector) => {
          injector.get(IsolatedQuerySpace).tableRendered.putValue(predecessor);
          injector.get(WorkPackageViewSelectionService).initializeSelection(['1', '2', '9']);
        },
      });
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '9']);

      await harness.render();

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
      expect(harness.row('1')).toHaveClass('-checked');
    });

    it('reconciles on a first render that is genuinely empty', async () => {
      harness = buildTable({
        workPackages: [],
        beforeAttach: (injector) => injector.get(WorkPackageViewSelectionService).initializeSelection(['7']),
      });
      await harness.render();
      expect(harness.selection.isEmpty).toBe(true);
    });

    it('never prunes from a table destroyed with a pending render', async () => {
      harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }] });
      await harness.render();
      harness.click('2');
      const frames:FrameRequestCallback[] = [];
      const frameSpy = vi.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => frames.push(callback));
      try {
        harness.querySpace.results.putValue({ elements: [buildWorkPackage({ id: '1' })] } as WorkPackageCollectionResource);
        harness.querySpace.initialized.putValue(null);
        expect(frames).toHaveLength(1);
        harness.table.destroy();
        frames.forEach((frame) => frame(0));
        expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      } finally {
        frameSpy.mockRestore();
      }
    });
  });
});
