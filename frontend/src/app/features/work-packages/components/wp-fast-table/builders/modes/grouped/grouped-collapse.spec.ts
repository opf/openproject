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

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

describe('Grouped table collapse', () => {
  let harness:TableHarness;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: newStatus } },
        { id: '3', attributes: { status: inProgressStatus } },
        { id: '4', attributes: { status: inProgressStatus } },
      ],
      groups: [
        { value: 'New', href: newStatus.href, count: 2 },
        { value: 'In progress', href: inProgressStatus.href, count: 2 },
      ],
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const toggleGroup = (index:number) => {
    fireEvent.click(harness.groupHeader(index).querySelector('.expander')!);
  };

  it('hides only the collapsed group members and restores them in order', async () => {
    toggleGroup(0);

    await waitFor(() => expect(harness.row('1')).not.toBeVisible());
    expect(harness.row('2')).not.toBeVisible();
    expect(harness.row('3')).toBeVisible();
    expect(harness.row('4')).toBeVisible();
    expect(harness.groupHeader(0)).toBeVisible();
    expect(within(harness.groupHeader(0)).getByText('js.label_expand')).toBeInTheDocument();
    expect(harness.rowIds()).toEqual(['1', '2', '3', '4']);
    expect(harness.renderedState()).toEqual([['1', true], ['2', true], ['3', false], ['4', false]]);

    toggleGroup(0);

    await waitFor(() => expect(harness.row('1')).toBeVisible());
    expect(harness.row('2')).toBeVisible();
    expect(within(harness.groupHeader(0)).getByText('js.label_collapse')).toBeInTheDocument();
    expect(harness.rowIds()).toEqual(['1', '2', '3', '4']);
    expect(harness.renderedState()).toEqual([['1', false], ['2', false], ['3', false], ['4', false]]);
  });

  it('keeps a group collapsed across a rerender with changed members', async () => {
    toggleGroup(0);
    await waitFor(() => expect(harness.row('1')).not.toBeVisible());

    await harness.render([
      { id: '1', subject: 'Renamed', attributes: { status: newStatus } },
      { id: '5', attributes: { status: newStatus } },
      { id: '3', attributes: { status: inProgressStatus } },
      { id: '6', attributes: { status: inProgressStatus } },
    ]);

    expect(harness.rowIds()).toEqual(['1', '5', '3', '6']);
    expect(harness.row('1')).not.toBeVisible();
    expect(harness.row('1')).toHaveTextContent('Renamed');
    expect(harness.row('5')).not.toBeVisible();
    expect(harness.row('3')).toBeVisible();
    expect(harness.row('6')).toBeVisible();
    expect(harness.renderedState()).toEqual([['1', true], ['5', true], ['3', false], ['6', false]]);

    toggleGroup(0);

    await waitFor(() => expect(harness.row('1')).toBeVisible());
    expect(harness.row('5')).toBeVisible();
    expect(harness.rowIds()).toEqual(['1', '5', '3', '6']);
    expect(harness.renderedState()).toEqual([['1', false], ['5', false], ['3', false], ['6', false]]);
  });
});
