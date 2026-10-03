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

const row = (id:number, name:string, { enabled = true, isDefault = false } = {}) => `
  <tr data-type-name="${name}">
    <td><span data-action="dragstart->sortable-types#start dragend->sortable-types#end">handle</span></td>
    <td><input type="checkbox" aria-label="Enable ${name}" ${enabled ? 'checked' : ''} data-action="change->sortable-types#toggle"></td>
    <td>${name}</td>
    <td><input name="type_scheme[types][${id}][position]" value="${id}"></td>
    <td><input type="radio" name="type_scheme[default_type_id]" value="${id}" aria-label="Default ${name}" ${isDefault ? 'checked' : ''}></td>
    <td>
      <span hidden data-sortable-types-target="control">
        <button type="button" data-action="sortable-types#up">${name} up</button>
        <button type="button" data-action="sortable-types#down">${name} down</button>
      </span>
    </td>
  </tr>`;

const template = `
  <div data-controller="sortable-types"
       data-sortable-types-moved-text-value="%{type} moved to position %{position} of %{total}"
       data-sortable-types-default-changed-text-value="Default type is now %{type}">
    <table>
      <tbody data-sortable-types-target="list" data-action="keydown->sortable-types#keydown">
        ${row(1, 'Epic', { isDefault: true })}
        ${row(2, 'Story')}
        ${row(3, 'Bug', { enabled: false })}
      </tbody>
    </table>
    <div data-sortable-types-target="status"></div>
  </div>
`;

describe('SortableTypesController', () => {
  let ctx:StimulusTestContext;

  const positionNames = () => Array.from(document.querySelectorAll<HTMLInputElement>('input[name$="[position]"]'))
    .map((input) => input.name);
  const positionValues = () => Array.from(document.querySelectorAll<HTMLInputElement>('input[name$="[position]"]'))
    .map((input) => input.value);
  const status = () => document.querySelector('[data-sortable-types-target="status"]')?.textContent;
  const radio = (name:string) => ctx.screen.getByLabelText<HTMLInputElement>(`Default ${name}`);
  const enable = (name:string) => ctx.screen.getByLabelText<HTMLInputElement>(`Enable ${name}`);

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

    expect(positionNames()).toEqual([
      'type_scheme[types][2][position]',
      'type_scheme[types][1][position]',
      'type_scheme[types][3][position]',
    ]);
    expect(positionValues()).toEqual(['1', '2', '3']);
    expect(status()).toBe('Epic moved to position 2 of 3');
  });

  it('moves a row up', () => {
    ctx.screen.getByRole('button', { name: 'Bug up' }).click();

    expect(positionNames()[1]).toBe('type_scheme[types][3][position]');
    expect(status()).toBe('Bug moved to position 2 of 3');
  });

  it('keeps focus on the pressed button after the move', () => {
    const button = ctx.screen.getByRole('button', { name: 'Epic down' });
    button.focus();
    button.click();

    expect(document.activeElement).toBe(button);
  });

  it('does nothing when moving the first row up', () => {
    ctx.screen.getByRole('button', { name: 'Epic up' }).click();

    expect(positionNames()[0]).toBe('type_scheme[types][1][position]');
    expect(status()).toBe('');
  });

  it('moves the row with Alt + ArrowDown and keeps focus', () => {
    const checkbox = enable('Epic');
    checkbox.focus();
    checkbox.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown', altKey: true, bubbles: true, cancelable: true }));

    expect(positionNames()[1]).toBe('type_scheme[types][1][position]');
    expect(document.activeElement).toBe(checkbox);
  });

  it('ignores arrow keys without Alt', () => {
    enable('Epic').dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true, cancelable: true }));

    expect(positionNames()[0]).toBe('type_scheme[types][1][position]');
  });

  it('disables the default radio of rows that are not enabled', () => {
    expect(radio('Bug')).toBeDisabled();
    expect(radio('Story')).toBeEnabled();
  });

  it('hands the default over to the first enabled type when the default type is unchecked', () => {
    enable('Epic').click();

    expect(radio('Epic')).toBeDisabled();
    expect(radio('Epic').checked).toBe(false);
    expect(radio('Story').checked).toBe(true);
    expect(status()).toBe('Default type is now Story');
  });

  it('makes a newly enabled type the default when no default is left', () => {
    enable('Epic').click();
    enable('Story').click();
    expect(document.querySelector('input[type="radio"]:checked')).toBeNull();

    enable('Bug').click();

    expect(radio('Bug')).toBeEnabled();
    expect(radio('Bug').checked).toBe(true);
  });
});
