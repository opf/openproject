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

import { DisplayFieldRenderer } from './display-field-renderer';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

describe('DisplayFieldRenderer', () => {
  it('leaves the span unlabelled when the field labels its own content', () => {
    const field = { labelsOwnContent: true, render: () => undefined, apply: () => undefined, isEmpty: () => false };
    const schema = { ofProperty: () => ({}), isAttributeEditable: () => false };
    const services = new Map<unknown, unknown>([
      [DisplayFieldService, { getField: () => field }],
      [SchemaCacheService, { of: () => schema }],
      [HalResourceEditingService, { typedState: () => ({ hasValue: () => false }) }],
    ]);

    const renderer = new DisplayFieldRenderer({ get: (token:unknown) => services.get(token) } as never, 'table');
    const span = renderer.render({} as HalResource, 'id', null);

    expect(span.hasAttribute('aria-label')).toBe(false);
  });
});
