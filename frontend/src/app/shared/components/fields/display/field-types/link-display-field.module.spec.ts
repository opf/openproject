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

import { within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { DisplayFieldContext } from 'core-app/shared/components/fields/display/display-field.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFieldSchema } from 'core-app/shared/components/fields/field.base';
import { LinkDisplayField } from './link-display-field.module';

describe('LinkDisplayField', () => {
  const injector = {
    get: (token:unknown, notFoundValue?:unknown) => (token === I18nService ? { t: (key:string) => key } : notFoundValue ?? {}),
  };

  const render = (options:DisplayFieldContext['options']) => {
    const field = new LinkDisplayField('website', { injector, container: 'table', options } as unknown as DisplayFieldContext);
    field.apply({ website: 'https://example.com', updateImmediately: true } as unknown as HalResource, { type: 'Link' } as IFieldSchema);
    const element = document.createElement('span');
    field.render(element, field.valueString);
    return element;
  };

  it('offers an edit trigger next to the link', () => {
    expect(within(render({})).getAllByRole('link')).toHaveLength(2);
  });

  it('renders only the link when the context is not writable', () => {
    const links = within(render({ writable: false })).getAllByRole('link');

    expect(links).toHaveLength(1);
    expect(links[0]).toHaveAttribute('href', 'https://example.com');
  });
});
