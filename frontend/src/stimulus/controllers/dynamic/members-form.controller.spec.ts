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

import { fireEvent } from '@testing-library/dom';
import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import MembersFormController from './members-form.controller';

describe('members form controller', () => {
  let ctx:StimulusTestContext;
  let originalOpenProject:OpenProject;

  beforeEach(async () => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();
    window.localStorage.removeItem('showFilter');

    ctx = await setupStimulusTest({
      controllers: { 'members-form': MembersFormController },
    });
  });

  afterEach(() => {
    ctx.dispose();
    window.localStorage.removeItem('showFilter');
    window.OpenProject = originalOpenProject;
  });

  it('toggles the filter on a page without the add member controls', async () => {
    await ctx.mount(`
      <div data-controller="members-form">
        <button type="button" data-members-form-target="filterMemberButton" data-action="members-form#toggleMemberFilter">
          Filter
        </button>
        <fieldset data-members-form-target="filterContainer">
          <legend>Filters</legend>
          <select aria-label="Status" data-members-form-target="statusSelect"></select>
        </fieldset>
      </div>
    `);

    expect(ctx.screen.getByRole('group', { name: 'Filters' })).toHaveClass('collapsed');

    fireEvent.click(ctx.screen.getByRole('button', { name: 'Filter' }));

    expect(ctx.screen.getByRole('group', { name: 'Filters' })).not.toHaveClass('collapsed');
    expect(ctx.screen.getByRole('combobox', { name: 'Status' })).toHaveFocus();
  });

  it('hides the add member form on a page without the add member button', async () => {
    await ctx.mount(`
      <div data-controller="members-form">
        <button type="button" data-members-form-target="filterMemberButton" data-action="members-form#toggleMemberFilter">
          Filter
        </button>
        <fieldset data-members-form-target="filterContainer">
          <select aria-label="Status" data-members-form-target="statusSelect"></select>
        </fieldset>
        <form data-testid="add-member-form" data-members-form-target="addMemberForm" style="display: block"></form>
      </div>
    `);

    fireEvent.click(ctx.screen.getByRole('button', { name: 'Filter' }));

    expect(ctx.screen.getByTestId('add-member-form')).not.toBeVisible();
  });

  it('ignores the add member button on a page without the add member form', async () => {
    await ctx.mount(`
      <div data-controller="members-form">
        <button type="button" data-members-form-target="filterMemberButton">Filter</button>
        <fieldset data-members-form-target="filterContainer"></fieldset>
        <button type="button"
                data-members-form-target="addMemberButton"
                data-action="members-form#showAddMemberForm"
                data-trigger-initially="true">
          Member
        </button>
      </div>
    `);

    fireEvent.click(ctx.screen.getByRole('button', { name: 'Member' }));

    expect(ctx.screen.getByRole('button', { name: 'Member' })).toBeEnabled();
  });
});
