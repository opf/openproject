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

import { TestBed } from '@angular/core/testing';
import {
  fieldName,
  option,
  renderInlineOptionsField,
} from 'core-app/shared/components/fields/edit/field-types/inline-options-edit-field/testing/render-inline-options-field';
import {
  CheckboxesEditFieldComponent,
} from 'core-app/shared/components/fields/edit/field-types/inline-options-edit-field/checkboxes-edit-field.component';

describe('CheckboxesEditFieldComponent', () => {
  const windows = option(1, 'Windows');
  const linux = option(2, 'Linux');
  const macos = option(3, 'macOS');

  function checkboxes(element:HTMLElement):HTMLInputElement[] {
    return Array.from(element.querySelectorAll<HTMLInputElement>('input[type="checkbox"]'));
  }

  it('renders one checkbox per option, checking the current values', async () => {
    const { element } = await renderInlineOptionsField(CheckboxesEditFieldComponent, [windows, linux, macos], [macos]);

    expect(Array.from(element.querySelectorAll('label')).map((label) => label.textContent.trim()))
      .toEqual(['Windows', 'Linux', 'macOS']);
    expect(checkboxes(element).map((checkbox) => checkbox.checked)).toEqual([false, false, true]);
  });

  it('adds and removes values in option order without submitting', async () => {
    const { element, resource, handler } = await renderInlineOptionsField(CheckboxesEditFieldComponent, [windows, linux, macos], [macos]);

    checkboxes(element)[0].click();
    expect(resource[fieldName]).toEqual([windows, macos]);

    checkboxes(element)[2].click();
    expect(resource[fieldName]).toEqual([windows]);

    expect(handler.handleUserSubmit).not.toHaveBeenCalled();
  });

  it('starts from an empty selection without a value', async () => {
    const { element, resource } = await renderInlineOptionsField(CheckboxesEditFieldComponent, [windows, linux], null);

    checkboxes(element)[1].click();

    expect(resource[fieldName]).toEqual([linux]);
  });

  it('shows the save/cancel controls outside of edit mode only', async () => {
    const inline = await renderInlineOptionsField(CheckboxesEditFieldComponent, [windows], []);
    expect(inline.element.querySelector('edit-field-controls')).not.toBeNull();

    TestBed.resetTestingModule();

    const editMode = await renderInlineOptionsField(CheckboxesEditFieldComponent, [windows], [], { inEditMode: true });
    expect(editMode.element.querySelector('edit-field-controls')).toBeNull();
  });
});
