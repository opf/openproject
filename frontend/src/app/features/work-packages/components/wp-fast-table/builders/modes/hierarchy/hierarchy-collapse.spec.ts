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

import { fireEvent, waitFor, within } from '@testing-library/dom';
import { buildTable, TableHarness } from '../../../testing/table-harness';
import { WorkPackageFixture } from '../../../testing/work-package-fixture';
import { States } from 'core-app/core/states/states.service';

const parent = { id: '1' };
const child = { id: '2', ancestors: [parent] };

describe('Hierarchy table collapse', () => {
  let harness:TableHarness;

  const renderHierarchy = async (workPackages:WorkPackageFixture[]) => {
    harness = buildTable({ workPackages, showHierarchies: true });
    await harness.render();
  };

  const toggle = (workPackageId:string) => {
    fireEvent.click(within(harness.row(workPackageId)).getByRole('button'));
  };

  afterEach(() => harness?.destroy());

  describe('with parent, child, grandchild and an unrelated row', () => {
    beforeEach(() => renderHierarchy([
      parent,
      child,
      { id: '3', ancestors: [parent, child] },
      { id: '4' },
    ]));

    it('hides the descendants of a collapsed parent and restores their order', async () => {
      expect(harness.rowIds()).toEqual(['1', '2', '3', '4']);

      toggle('1');

      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      expect(harness.row('3')).not.toBeVisible();
      expect(harness.row('1')).toBeVisible();
      expect(harness.row('4')).toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', true], ['3', true], ['4', false]]);

      toggle('1');

      await waitFor(() => expect(harness.row('2')).toBeVisible());
      expect(harness.row('3')).toBeVisible();
      expect(harness.rowIds()).toEqual(['1', '2', '3', '4']);
      expect(harness.renderedState()).toEqual([['1', false], ['2', false], ['3', false], ['4', false]]);
    });

    it('keeps nested collapse state independent of the parent', async () => {
      toggle('2');
      await waitFor(() => expect(harness.row('3')).not.toBeVisible());

      toggle('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());

      toggle('1');
      await waitFor(() => expect(harness.row('2')).toBeVisible());
      expect(harness.row('3')).not.toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', false], ['3', true], ['4', false]]);

      toggle('2');
      await waitFor(() => expect(harness.row('3')).toBeVisible());
      expect(harness.renderedState()).toEqual([['1', false], ['2', false], ['3', false], ['4', false]]);

      // Parent collapsed over an explicitly expanded child: both entries are processed.
      toggle('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      expect(harness.row('3')).not.toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', true], ['3', true], ['4', false]]);
    });

    it('keeps a parent collapsed across a rerender with changed descendants', async () => {
      toggle('1');
      await waitFor(() => expect(harness.row('2')).not.toBeVisible());

      await harness.render([
        { id: '1', subject: 'Renamed parent' },
        child,
        { id: '5', ancestors: [parent] },
        { id: '4' },
      ]);

      expect(harness.rowIds()).toEqual(['1', '2', '5', '4']);
      expect(harness.row('1')).toHaveTextContent('Renamed parent');
      expect(harness.row('2')).not.toBeVisible();
      expect(harness.row('5')).not.toBeVisible();
      expect(harness.row('4')).toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', true], ['5', true], ['4', false]]);

      toggle('1');

      await waitFor(() => expect(harness.row('2')).toBeVisible());
      expect(harness.row('5')).toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', false], ['5', false], ['4', false]]);
    });
  });

  describe('with a contextual ancestor outside the results', () => {
    beforeEach(() => renderHierarchy([
      { id: '2', ancestors: [parent] },
      { id: '3', ancestors: [parent] },
      { id: '4' },
    ]));

    it('collapses and expands the real descendant rows', async () => {
      expect(harness.row('1')).toHaveAttribute('data-class-identifier', 'wp-ancestor-row-1');
      expect(harness.rowIds()).toEqual(['1', '2', '3', '4']);

      toggle('1');

      await waitFor(() => expect(harness.row('2')).not.toBeVisible());
      expect(harness.row('3')).not.toBeVisible();
      expect(harness.row('1')).toBeVisible();
      expect(harness.row('4')).toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', true], ['3', true], ['4', false]]);

      toggle('1');

      await waitFor(() => expect(harness.row('2')).toBeVisible());
      expect(harness.row('3')).toBeVisible();
      expect(harness.renderedState()).toEqual([['1', false], ['2', false], ['3', false], ['4', false]]);
    });
  });

  describe('with two tables showing the same hierarchy in different positions', () => {
    const unrelated = { id: '9' };
    const harnesses:TableHarness[] = [];
    let first:TableHarness;
    let second:TableHarness;

    const mountHierarchy = async (workPackages:WorkPackageFixture[], states:States) => {
      const table = buildTable({
        workPackages, showHierarchies: true, timelineVisible: true, states,
      });
      harnesses.push(table);
      await table.render();
      return table;
    };

    const toggleIn = (table:TableHarness, workPackageId:string) => {
      fireEvent.click(within(table.row(workPackageId)).getByRole('button'));
    };

    const indicator = (table:TableHarness, workPackageId:string) => within(table.row(workPackageId)).getByRole('button');

    beforeEach(async () => {
      const states = new States();
      first = await mountHierarchy([unrelated, parent, child], states);
      second = await mountHierarchy([parent, child, unrelated], states);
    });

    afterEach(async () => {
      await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
    });

    it('collapses a hierarchy and its timeline only in its own table', async () => {
      toggleIn(first, '1');

      await waitFor(() => expect(first.row('2')).not.toBeVisible());
      expect(first.timelineRow('2')).not.toBeVisible();
      expect(first.timelineRow('1')).toHaveClass('__hierarchy-root-collapsed');
      expect(first.renderedState()).toEqual([['9', false], ['1', false], ['2', true]]);

      expect(second.row('2')).toBeVisible();
      expect(second.timelineRow('2')).toBeVisible();
      expect(second.timelineRow('1')).not.toHaveClass('__hierarchy-root-collapsed');
      expect(indicator(second, '1')).not.toHaveClass('-hierarchy-collapsed');
      expect(second.renderedState()).toEqual([['1', false], ['2', false], ['9', false]]);
    });

    it('keeps a collapsed hierarchy when the other table expands its own', async () => {
      toggleIn(first, '1');
      await waitFor(() => expect(first.row('2')).not.toBeVisible());

      toggleIn(second, '1');
      await waitFor(() => expect(second.row('2')).not.toBeVisible());
      expect(second.renderedState()).toEqual([['1', false], ['2', true], ['9', false]]);

      toggleIn(second, '1');
      await waitFor(() => expect(second.row('2')).toBeVisible());
      expect(second.timelineRow('2')).toBeVisible();
      expect(second.timelineRow('1')).not.toHaveClass('__hierarchy-root-collapsed');

      expect(first.row('2')).not.toBeVisible();
      expect(first.timelineRow('2')).not.toBeVisible();
      expect(first.timelineRow('1')).toHaveClass('__hierarchy-root-collapsed');
      expect(indicator(first, '1')).toHaveClass('-hierarchy-collapsed');
      expect(first.renderedState()).toEqual([['9', false], ['1', false], ['2', true]]);
    });

    it('scrolls the toggled row into view in its own table', async () => {
      [first, second].forEach((table) => {
        // A fixed height makes the table side overflow, so it is the scroll parent the helper picks.
        table.container.style.height = '20px';
        table.container.scrollTop = table.container.scrollHeight;
      });
      const firstScroll = first.container.scrollTop;
      expect(second.container.scrollTop).toBeGreaterThan(0);

      toggleIn(second, '1');

      await waitFor(() => expect(second.container.scrollTop).toBe(second.row('1').offsetTop));
      expect(first.container.scrollTop).toBe(firstScroll);
    });
  });
});
