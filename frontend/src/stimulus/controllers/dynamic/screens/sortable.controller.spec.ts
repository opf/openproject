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
import SortableController from './sortable.controller';

const item = (id:number, fieldKey:string, position:number) => `
  <tr id="screen-item-${id}" tabindex="-1" data-screens--sortable-target="item" data-field-key="${fieldKey}">
    <td>${fieldKey}</td>
    <td><input name="screen[sections][0][items][${position - 1}][position]" value="${position}" data-screens--sortable-target="itemPosition"></td>
    <td><input type="hidden" name="screen[sections][0][items][${position - 1}][section_id]" value="1" data-screens--sortable-target="itemSection"></td>
  </tr>`;

const section = (id:number, name:string, rows:string) => `
  <fieldset id="screen-section-${id}" data-section-id="${id}" data-screens--sortable-target="section">
    <input name="screen[sections][${id - 1}][name]" value="${name}">
    <table><tbody>${rows}</tbody></table>
  </fieldset>`;

const template = `
  <div data-controller="screens--sortable"
       data-screens--sortable-moved-text-value="%{field} moved to %{section}, position %{position} of %{total}">
    <div data-screens--sortable-target="list">
      ${section(1, 'General', item(1, 'Subject', 1) + item(2, 'Priority', 2))}
      ${section(2, 'Assignment', item(3, 'Assignee', 1))}
    </div>
    <div data-screens--sortable-target="status"></div>
  </div>`;

describe('ScreensSortableController', () => {
  let ctx:StimulusTestContext;
  let controller:SortableController;

  const positions = () => Array.from(document.querySelectorAll<HTMLInputElement>('[data-screens--sortable-target="itemPosition"]'))
    .map((input) => input.value);
  const status = () => document.querySelector('[data-screens--sortable-target="status"]')?.textContent;

  beforeEach(async () => {
    ctx = await setupStimulusTest({ controllers: { 'screens--sortable': SortableController } });
    await ctx.mount(template);
    const root = document.querySelector('[data-controller="screens--sortable"]') as HTMLElement;
    controller = ctx.application.getControllerForElementAndIdentifier(root, 'screens--sortable') as SortableController;
  });

  afterEach(() => ctx.dispose());

  it('moves an item into another section and renumbers positions', () => {
    controller.move('screen-item-1', 'screen-section-2', 0);

    const target = document.querySelector('#screen-section-2') as HTMLElement;
    expect(Array.from(target.querySelectorAll('[data-screens--sortable-target="item"]')).map((el) => el.id))
      .toEqual(['screen-item-1', 'screen-item-3']);
    expect(positions()).toEqual(['1', '1', '2']);
  });

  it('updates the section input of the moved item', () => {
    controller.move('screen-item-1', 'screen-section-2', 0);

    const input = document.querySelector('#screen-item-1 [data-screens--sortable-target="itemSection"]') as HTMLInputElement;
    expect(input.value).toBe('2');
  });

  it('announces the move with the interpolated message', () => {
    controller.move('screen-item-1', 'screen-section-2', 0);

    expect(status()).toBe('Subject moved to Assignment, position 1 of 2');
  });

  it('returns focus to the moved item', () => {
    controller.move('screen-item-1', 'screen-section-2', 0);

    expect(document.activeElement?.id).toBe('screen-item-1');
  });
});
