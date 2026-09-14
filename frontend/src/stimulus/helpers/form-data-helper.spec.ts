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

import { filterFormData } from './form-data-helper';

describe('filterFormData', () => {
  function buildForm(fields:[name:string, value:string][]):HTMLFormElement {
    const form = document.createElement('form');

    fields.forEach(([name, value]) => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      form.append(input);
    });

    return form;
  }

  it('keeps entries the predicate accepts, preserving order and repeated keys', () => {
    const form = buildForm([
      ['ids[]', '1'],
      ['ids[]', '2'],
      ['notes', 'hello'],
    ]);

    const result = filterFormData(form, () => true);

    expect([...result.entries()]).toEqual([
      ['ids[]', '1'],
      ['ids[]', '2'],
      ['notes', 'hello'],
    ]);
  });

  it('drops entries the predicate rejects', () => {
    const form = buildForm([
      ['_method', 'patch'],
      ['subject', 'Refresh me'],
    ]);

    const result = filterFormData(form, (_value, key) => key !== '_method');

    expect([...result.entries()]).toEqual([['subject', 'Refresh me']]);
  });

  it('passes (value, key) to the predicate', () => {
    const form = buildForm([['status_id', '4']]);
    const seen:[FormDataEntryValue, string][] = [];

    filterFormData(form, (value, key) => {
      seen.push([value, key]);
      return true;
    });

    expect(seen).toEqual([['4', 'status_id']]);
  });

  it('lets a typeof-string predicate drop File entries', () => {
    const form = buildForm([['notes', 'keep']]);
    const fileInput = document.createElement('input');
    fileInput.type = 'file';
    fileInput.name = 'attachment';
    const transfer = new DataTransfer();
    transfer.items.add(new File(['x'], 'x.txt', { type: 'text/plain' }));
    fileInput.files = transfer.files;
    form.append(fileInput);

    const result = filterFormData(form, (value) => typeof value === 'string');

    expect([...result.keys()]).toEqual(['notes']);
  });

  it('does not modify the source form', () => {
    const form = buildForm([
      ['_method', 'patch'],
      ['notes', 'kept on form'],
    ]);

    filterFormData(form, (_value, key) => key !== '_method');

    expect([...new FormData(form).keys()]).toEqual(['_method', 'notes']);
  });
});
