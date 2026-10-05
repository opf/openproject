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

import { fireEvent, waitFor } from '@testing-library/dom';
import { buildTable, TableHarness, TableHarnessOptions } from '../../testing/table-harness';

describe('Work package hover preview', () => {
  let harness:TableHarness;

  const preview = () => document.querySelector<HTMLElement>('.wp-hover-preview');

  const render = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: [{
        id: '1',
        subject: 'Fix the thing',
        attributes: {
          estimatedTime: 'PT8H',
          remainingTime: 'PT4H',
          spentTime: 'PT2H',
          assignee: { name: 'Jane Doe' },
        },
      }],
      ...options,
    });
    await harness.render();
  };

  afterEach(() => {
    preview()?.remove();
    harness.destroy();
  });

  it('shows the basic fields after hovering a row', async () => {
    await render();

    fireEvent.mouseOver(harness.row('1').querySelector('td')!);

    await waitFor(() => expect(preview()).toBeTruthy());
    expect(preview()).toHaveTextContent('Jane Doe');
    expect(preview()).toHaveTextContent('js.work_packages.properties.workAlternative');
    expect(preview()).toHaveTextContent('js.work_packages.properties.spentTime');
    expect(preview()).toHaveTextContent('js.work_packages.properties.remainingTime');
  });

  it('removes the preview when the pointer leaves the row', async () => {
    await render();

    const cell = harness.row('1').querySelector('td')!;
    fireEvent.mouseOver(cell);
    await waitFor(() => expect(preview()).toBeTruthy());

    fireEvent.mouseOut(cell, { relatedTarget: document.body });

    expect(preview()).toBeNull();
  });
});
