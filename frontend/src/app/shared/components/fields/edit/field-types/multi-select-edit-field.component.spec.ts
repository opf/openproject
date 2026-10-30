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

import { MultiSelectEditFieldComponent } from './multi-select-edit-field.component';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

describe('multi-select integration contracts', () => {
  it('preserves option references and clears to an empty collection', () => {
    const field = Object.create(MultiSelectEditFieldComponent.prototype) as MultiSelectEditFieldComponent;
    const option = Object.create(HalResource.prototype) as HalResource;
    Object.defineProperty(option, 'href', { value: '/api/v3/users/42' });
    Object.assign(field, { resource: {}, name: 'watchers', availableOptions: [option] });
    const selected = [option];
    field.selectedOption = selected;
    expect(field.selectedOption).toBe(selected);
    expect(field.resource.watchers).toEqual(selected);
    expect((field.resource.watchers as HalResource[])[0]).toBe(option);
    field.selectedOption = [];
    expect(field.resource.watchers).toEqual([]);
  });

  it('reads the project ID only from a HAL resource', () => {
    const project = Object.create(HalResource.prototype) as HalResource;
    Object.defineProperty(project, 'id', { value: '42' });
    expect(Reflect.get(MultiSelectEditFieldComponent.prototype, 'projectId', { resource: { project } })).toBe('42');
    expect(Reflect.get(MultiSelectEditFieldComponent.prototype, 'projectId', { resource: {} })).toBeNull();
  });
});
