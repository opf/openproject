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

import { within } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { buildTable, TableHarness } from '../../../testing/table-harness';
import { buildWorkPackage } from '../../../testing/work-package-fixture';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';

describe('Hierarchy ordering across query windows', () => {
  let harness:TableHarness;
  const parent = { id: '1' };
  const child = { id: '2', ancestors: [parent] };
  const other = { id: '3' };

  afterEach(() => harness?.destroy());

  it('inserts a parent absent from the result window before its first child', async () => {
    harness = buildTable({ workPackages: [child, other], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
  });

  it('renders a filtered-out parent before its deferred leaf', async () => {
    harness = buildTable({ workPackages: [{ id: '4', ancestors: [parent, { id: '5' }] }, parent], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '5', '4']);
  });

  it('currently defers the child when its parent is in the same window', async () => {
    harness = buildTable({ workPackages: [child, other, parent], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['3', '1', '2']);
  });

  describe('when the cache moves a deferred child under a parent outside the results', () => {
    const moveChild = () => harness.injector.get(States).workPackages.get('2')
      .putValue(buildWorkPackage({ id: '2', subject: 'Moved', ancestors: [{ id: '9' }], attributes: { parent: { id: '9' } } }));

    it('redraws the child under its query parent with current cells', async () => {
      harness = buildTable({ workPackages: [child, other, parent], showHierarchies: true });
      await harness.render();
      moveChild();

      const rendered = harness.nextRender();
      expect(() => harness.table.redrawTable()).not.toThrow();
      await rendered;

      expect(harness.rowIds()).toEqual(['3', '1', '2']);
      expect(harness.row('2')).toHaveTextContent('Moved');
    });

    it('rebuilds a pending render for a collapse without losing the child', async () => {
      harness = buildTable({ workPackages: [child, other, parent], showHierarchies: true });
      await harness.render();
      const frames = harness.holdFrames();
      try {
        harness.table.redrawTable();
        moveChild();

        expect(() => harness.table.setHidden(new Map([[wpOccurrenceKey('2'), false]]))).not.toThrow();
        frames.commit();

        expect(harness.rowIds()).toEqual(['3', '1', '2']);
        expect(harness.row('2')).toHaveTextContent('Moved');
      } finally {
        frames.release();
      }
    });
  });

  it('keeps the query depth when the cache makes a nested child a root', async () => {
    harness = buildTable({ workPackages: [parent, child, other], showHierarchies: true });
    await harness.render();
    const subjectCell = () => within(harness.row('2')).getByRole('rowheader');
    const indentation = subjectCell().style.minWidth;
    expect(harness.row('2')).toHaveAttribute('aria-level', '2');

    harness.injector.get(States).workPackages.get('2').putValue(buildWorkPackage({ id: '2', subject: 'Root now' }));
    const rendered = harness.nextRender();
    harness.table.redrawTable();
    await rendered;

    expect(harness.row('2')).toHaveTextContent('Root now');
    expect(harness.row('2')).toHaveAttribute('aria-level', '2');
    expect(subjectCell().style.minWidth).toBe(indentation);
  });

  it('keeps a child under an earlier parent', async () => {
    harness = buildTable({ workPackages: [parent, other, child], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
  });
});
