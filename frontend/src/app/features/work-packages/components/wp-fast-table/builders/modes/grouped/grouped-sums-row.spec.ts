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

describe('Grouped table sums rows', () => {
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
        { value: 'New', href: newStatus.href, count: 2, sums: { storyPoints: 13 } },
        { value: 'In progress', href: inProgressStatus.href, count: 2, sums: { storyPoints: 21 } },
      ],
      timelineVisible: true,
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const toggleGroup = (index:number) => {
    fireEvent.click(harness.groupHeader(index).querySelector('.expander')!);
  };

  const sumLabels = () => within(harness.tbody).getAllByText('js.label_sum');
  const sumsRow = (index:number) => sumLabels()[index].closest('tr')!;
  const sumsTimelineRow = (index:number) => harness.timelineRowOf(sumsRow(index));
  const sumOf = (value:number) => within(harness.tbody).getByText(String(value));

  const addStoryPointsColumn = async () => {
    harness.setColumns(['id', 'subject', 'storyPoints']);
    await waitFor(() => expect(sumOf(21)).toBeVisible());
  };

  it('ends every group with a sums row', () => {
    expect(sumLabels()).toHaveLength(2);
    expect(harness.row('2').nextElementSibling).toContainElement(sumLabels()[0]);
    expect(harness.row('4').nextElementSibling).toContainElement(sumLabels()[1]);
    sumLabels().forEach((label) => expect(label).toBeVisible());
    expect(sumsTimelineRow(0)).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();
  });

  it('hides the sums row of a collapsed group', async () => {
    toggleGroup(0);

    await waitFor(() => expect(sumLabels()[0]).not.toBeVisible());
    expect(sumsTimelineRow(0)).not.toBeVisible();
    expect(sumLabels()[1]).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();

    toggleGroup(0);

    await waitFor(() => expect(sumLabels()[0]).toBeVisible());
    expect(sumsTimelineRow(0)).toBeVisible();
  });

  it('keeps the sums row of a collapsed group hidden when a column is added', async () => {
    toggleGroup(0);
    await waitFor(() => expect(sumLabels()[0]).not.toBeVisible());

    await addStoryPointsColumn();

    expect(harness.row('1')).not.toBeVisible();
    expect(sumLabels()[0]).not.toBeVisible();
    expect(sumOf(13)).not.toBeVisible();
    expect(sumsTimelineRow(0)).not.toBeVisible();
    expect(sumLabels()[1]).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();

    toggleGroup(0);

    await waitFor(() => expect(sumOf(13)).toBeVisible());
    expect(sumLabels()[0]).toBeVisible();
    expect(sumsTimelineRow(0)).toBeVisible();
  });

  it('shows the sums row of an expanded group when a column is added', async () => {
    await addStoryPointsColumn();

    expect(sumLabels()[0]).toBeVisible();
    expect(sumOf(13)).toBeVisible();
    expect(sumLabels()[1]).toBeVisible();
    expect(sumsTimelineRow(0)).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();
  });
});
