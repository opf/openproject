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

import {
  fieldName,
  option,
  renderInlineOptionsField,
} from 'core-app/shared/components/fields/edit/field-types/inline-options-edit-field/testing/render-inline-options-field';
import {
  RadioButtonsEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/inline-options-edit-field/radio-buttons-edit-field.component';

describe('RadioButtonsEditFieldComponent', () => {
  const low = option(1, 'low');
  const high = option(2, 'high');

  function labels(element:HTMLElement):string[] {
    return Array.from(element.querySelectorAll('label')).map((label) => label.textContent.trim());
  }

  function radios(element:HTMLElement):HTMLInputElement[] {
    return Array.from(element.querySelectorAll<HTMLInputElement>('input[type="radio"]'));
  }

  it('renders one radio button per option plus an empty choice, checking the current value', async () => {
    const { element } = await renderInlineOptionsField(RadioButtonsEditFieldComponent, [low, high], high);

    expect(element.querySelector('fieldset')!.getAttribute('role')).toEqual('radiogroup');
    expect(labels(element)).toEqual(['js.placeholders.default', 'low', 'high']);
    expect(radios(element).map((radio) => radio.checked)).toEqual([false, false, true]);
    expect(new Set(radios(element).map((radio) => radio.name))).toEqual(new Set(['inline-options-field']));
  });

  it('checks the empty choice without a value', async () => {
    const { element } = await renderInlineOptionsField(RadioButtonsEditFieldComponent, [low, high], null);

    expect(radios(element).map((radio) => radio.checked)).toEqual([true, false, false]);
  });

  it('has no empty choice for required fields', async () => {
    const { element } = await renderInlineOptionsField(RadioButtonsEditFieldComponent, [low, high], low, { required: true });

    expect(labels(element)).toEqual(['low', 'high']);
  });

  it('sets the value and submits when an option is selected', async () => {
    const { element, resource, handler } = await renderInlineOptionsField(RadioButtonsEditFieldComponent, [low, high], null);

    radios(element)[2].click();

    expect(resource[fieldName]).toBe(high);
    expect(handler.handleUserSubmit).toHaveBeenCalledTimes(1);
  });

  it('clears the value with the empty choice', async () => {
    const { element, resource } = await renderInlineOptionsField(RadioButtonsEditFieldComponent, [low, high], low);

    radios(element)[0].click();

    expect(resource[fieldName]).toEqual(expect.objectContaining({ href: null }));
  });
});
