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

import { ResourcesDisplayField } from './resources-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { URN_UNDISCLOSED } from 'core-app/core/apiv3/api-v3-urns';

describe('ResourcesDisplayField', () => {
  const mockI18n = { t: (key:string) => key };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
  ]);

  const mockInjector = {
    get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
  };

  function buildField(name:string, type:string, values:string[]):ResourcesDisplayField {
    return buildFieldFor(name, type, values.map((value) => ({ name: value })));
  }

  function buildFieldFor(name:string, type:string, values:{ name:string, href?:string }[]):ResourcesDisplayField {
    const resource = {
      [name]: values,
    } as unknown as HalResource;

    const field = new ResourcesDisplayField(name, {
      injector: mockInjector,
      container: 'single-view',
      options: {},
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type } as IFieldSchema);

    return field;
  }

  it('joins the resource names with a comma for valueString', () => {
    const field = buildField('labels', '[]Label', ['Bug', 'Feature', 'Needs review']);

    expect(field.valueString).toEqual('Bug, Feature, Needs review');
  });

  it('returns an empty string for valueString when there are no values', () => {
    const field = buildField('labels', '[]Label', []);

    expect(field.valueString).toEqual('');
  });

  it('joins target version names with a comma for valueString', () => {
    const field = buildField('targetVersions', '[]Version', ['Version 1', 'Version 2']);

    expect(field.valueString).toEqual('Version 1, Version 2');
  });

  it('renders undisclosed values muted', () => {
    const field = buildFieldFor('customField1', '[]CustomOption', [
      { name: 'A', href: '/api/v3/custom_options/1' },
      { name: '(Value no longer available)', href: URN_UNDISCLOSED },
    ]);
    const element = document.createElement('div');

    field.render(element, field.valueString);

    const muted = element.querySelectorAll('.color-fg-subtle');
    expect(muted.length).toEqual(1);
    expect(muted[0].textContent).toEqual('(Value no longer available)');
    expect(element.textContent).toEqual('A, (Value no longer available)');
  });
});
