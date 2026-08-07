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

import { SingleLineResourcesDisplayField } from './single-line-resources-display-field.module';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';

describe('SingleLineResourcesDisplayField', () => {
  let field:SingleLineResourcesDisplayField;
  let element:HTMLElement;

  const mockI18n = { t: (key:string) => key };

  const serviceMap = new Map<unknown, unknown>([
    [I18nService, mockI18n],
  ]);

  const mockInjector = {
    get: (token:unknown, notFoundValue?:unknown) => serviceMap.get(token) ?? notFoundValue ?? {},
  };

  function render(values:string[]) {
    const resource = {
      targetVersions: values.map((name) => ({ name })),
    } as unknown as HalResource;

    field = new SingleLineResourcesDisplayField('targetVersions', {
      injector: mockInjector,
      container: 'single-view',
      options: { layout: 'singleline' },
    } as unknown as DisplayFieldContext);

    field.apply(resource, { type: '[]Version' } as IFieldSchema);

    element = document.createElement('div');
    field.render(element, field.valueString);
  }

  it('renders all values comma-separated on one line', () => {
    render(['Sprint 1', 'Master backlog', 'backlog']);

    expect(element.textContent).toEqual('Sprint 1, Master backlog, backlog');
  });

  it('renders every value in full for more than two values', () => {
    render(['Sprint 1', 'Master backlog', 'backlog', 'Release 1.0.0']);

    expect(element.textContent).toEqual('Sprint 1, Master backlog, backlog, Release 1.0.0');
  });

  it('renders a single value plainly', () => {
    render(['Sprint 1']);

    expect(element.textContent).toEqual('Sprint 1');
  });

  it('keeps the full value list as the element title', () => {
    render(['Sprint 1', 'Master backlog']);

    expect(element.getAttribute('title')).toEqual('Sprint 1, Master backlog');
  });

  it('renders the placeholder for an empty value list', () => {
    render([]);

    expect(element.textContent).toEqual('js.placeholders.default');
  });
});
