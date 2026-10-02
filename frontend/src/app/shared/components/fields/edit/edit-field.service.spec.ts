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

import { EditFieldService, IEditFieldType } from 'core-app/shared/components/fields/edit/edit-field.service';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('EditFieldService#getClassForSchema', () => {
  class SelectField {}
  class MultiSelectField {}
  class RadioButtonsField {}
  class CheckboxesField {}

  let service:EditFieldService;

  function schema(type:string, options?:Record<string, unknown>):IFieldSchema {
    return { type, options } as unknown as IFieldSchema;
  }

  beforeEach(() => {
    service = new EditFieldService();
    service
      .addFieldType(SelectField, 'select', ['CustomOption'])
      .addFieldType(MultiSelectField, 'multi-select', ['[]CustomOption'])
      .addFieldType(RadioButtonsField, 'radio_buttons', [])
      .addFieldType(CheckboxesField, 'checkboxes', []);
  });

  it('picks the inline field named by options.displayAs', () => {
    expect(service.getClassForSchema('WorkPackage', 'customField1', schema('CustomOption', { displayAs: 'radio_buttons' })))
      .toBe(RadioButtonsField as unknown as IEditFieldType);
    expect(service.getClassForSchema('WorkPackage', 'customField2', schema('[]CustomOption', { displayAs: 'checkboxes' })))
      .toBe(CheckboxesField as unknown as IEditFieldType);
  });

  it('falls back to the type lookup without displayAs', () => {
    expect(service.getClassForSchema('WorkPackage', 'customField1', schema('CustomOption')))
      .toBe(SelectField as unknown as IEditFieldType);
  });

  it('falls back to the type lookup for an unknown displayAs value', () => {
    expect(service.getClassForSchema('WorkPackage', 'customField1', schema('CustomOption', { displayAs: 'dropdown' })))
      .toBe(SelectField as unknown as IEditFieldType);
  });

  it('keeps the dropdown when the form does not allow inline options (work package table)', () => {
    expect(service.getClassForSchema('WorkPackage', 'customField2', schema('[]CustomOption', { displayAs: 'checkboxes' }), false))
      .toBe(MultiSelectField as unknown as IEditFieldType);
  });
});
