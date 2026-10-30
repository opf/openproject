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

import { LabelsDisplayField } from './labels-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('LabelsDisplayField', () => {
  const mockI18n = { t: (key:string) => key };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
  ]);

  const mockInjector = {
    get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
  };

  function render(container:DisplayFieldContext['container'], names:string[]):HTMLElement {
    const resource = {
      labels: names.map((name) => ({ name })),
    } as unknown as HalResource;

    const field = new LabelsDisplayField('labels', {
      injector: mockInjector,
      container,
      options: {},
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type: '[]Label' } as IFieldSchema);

    const element = document.createElement('div');
    field.render(element, field.valueString);

    return element;
  }

  function labelTexts(element:HTMLElement):string[] {
    return Array.from(element.querySelectorAll('.Label')).map((label) => label.textContent!);
  }

  it('renders every label as a large Primer label in the single view', () => {
    const element = render('single-view', ['Bug', 'Feature', 'Needs review']);

    expect(labelTexts(element)).toEqual(['Bug', 'Feature', 'Needs review']);
    expect(element.querySelectorAll('.Label--large').length).toEqual(3);
    expect(element.querySelector('.badge')).toBeNull();
  });

  it('renders the first two labels followed by an ellipsis and the total count in the table', () => {
    const element = render('table', ['Bug', 'Feature', 'Needs review']);

    expect(labelTexts(element)).toEqual(['Bug', 'Feature']);
    expect(element.querySelector('.Label--large')).toBeNull();
    expect(element.querySelector('.badge')!.textContent).toEqual('3');
    expect(element.textContent).toEqual('BugFeature...3');
  });

  it('renders no ellipsis or count in the table when all labels are shown', () => {
    const element = render('table', ['Bug', 'Feature']);

    expect(labelTexts(element)).toEqual(['Bug', 'Feature']);
    expect(element.querySelector('.badge')).toBeNull();
    expect(element.textContent).not.toContain('...');
  });
});
