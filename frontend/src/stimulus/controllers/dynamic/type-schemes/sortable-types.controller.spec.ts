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

import { setupStimulusTest, type StimulusTestContext } from 'core-stimulus/test-helpers';
import SortableTypesController from './sortable-types.controller';

const template = `
  <div data-controller="sortable-types" data-sortable-types-moved-text-value="%{type} moved to %{position} of %{total}">
    <table><tbody data-sortable-types-target="list">
      <tr data-sortable-types-target="row"><td></td><td></td><td>Epic</td>
        <td><input name="type_scheme[types][1][position]" value="1" data-sortable-types-target="position"></td><td></td>
        <td><button type="button" hidden data-sortable-types-target="control" data-action="sortable-types#up">Epic up</button>
            <button type="button" hidden data-sortable-types-target="control" data-action="sortable-types#down">Epic down</button></td></tr>
      <tr data-sortable-types-target="row"><td></td><td></td><td>Story</td>
        <td><input name="type_scheme[types][2][position]" value="2" data-sortable-types-target="position"></td><td></td>
        <td><button type="button" hidden data-sortable-types-target="control" data-action="sortable-types#up">Story up</button>
            <button type="button" hidden data-sortable-types-target="control" data-action="sortable-types#down">Story down</button></td></tr>
    </tbody></table>
    <div data-sortable-types-target="status"></div>
  </div>
`;

describe('SortableTypesController', () => {
  let ctx:StimulusTestContext;

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { 'sortable-types': SortableTypesController } });
    await ctx.mount(template);
  });

  afterEach(() => ctx.dispose());

  it('reveals the move buttons once connected', () => {
    expect(ctx.screen.getByRole('button', { name: 'Epic up' })).toBeVisible();
  });

  it('moves a row down, renumbers positions and announces the move', () => {
    ctx.screen.getByRole('button', { name: 'Epic down' }).click();

    const positions = Array.from(document.querySelectorAll<HTMLInputElement>('input[name$="[position]"]'));
    expect(positions.map((input) => input.name)).toEqual([
      'type_scheme[types][2][position]',
      'type_scheme[types][1][position]',
    ]);
    expect(positions.map((input) => input.value)).toEqual(['1', '2']);
    expect(document.querySelector('[data-sortable-types-target="status"]')?.textContent).toBe('Epic moved to 2 of 2');
  });

  it('does nothing when moving the first row up', () => {
    ctx.screen.getByRole('button', { name: 'Epic up' }).click();

    const first = document.querySelector<HTMLInputElement>('input[name$="[position]"]');
    expect(first?.name).toBe('type_scheme[types][1][position]');
  });
});
