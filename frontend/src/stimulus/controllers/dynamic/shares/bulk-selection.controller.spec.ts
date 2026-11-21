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
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import BulkSelectionController from './bulk-selection.controller';

describe('shares bulk selection controller', () => {
  let ctx:StimulusTestContext;

  const dialog = (body:string) => `
    <div data-controller="shares--bulk-selection">
      <div data-shares--bulk-selection-target="defaultActions"></div>
      <div data-shares--bulk-selection-target="bulkActions" hidden></div>
      ${body}
    </div>
  `;

  const target = (name:string) => ctx.container.querySelector<HTMLElement>(`[data-shares--bulk-selection-target="${name}"]`)!;

  const roleButton = `
    <button data-shares--bulk-selection-target="userRowRole" disabled>
      <span class="Button-label">Edit</span>
    </button>
  `;

  beforeEach(async () => {
    ctx = await setupStimulusTest({
      controllers: { 'shares--bulk-selection': BulkSelectionController },
    });
  });

  afterEach(() => {
    ctx.dispose();
  });

  it('connects in a read-only dialog without bulk controls', async () => {
    await ctx.mount(dialog(roleButton));

    // A failing connect surfaces as an unhandled error, which fails the run.
    expect(ctx.getController('shares--bulk-selection')).toBeInstanceOf(BulkSelectionController);
  });

  it('refreshes without a toggle-all checkbox when the last editable share is removed', async () => {
    await ctx.mount(dialog(`
      <input type="checkbox" value="1" data-shares--bulk-selection-target="shareCheckbox">
      ${roleButton}
    `));

    target('shareCheckbox').remove();

    await waitFor(() => {
      expect(target('defaultActions')).toBeVisible();
      expect(target('bulkActions')).not.toBeVisible();
    });
  });
});
