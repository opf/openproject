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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { QueryFilterInstanceSchemaResource } from 'core-app/features/hal/resources/query-filter-instance-schema-resource';

interface SchemaWithAllowedValuesCheck {
  _dependencies:{ dependencies:Record<string, { values?:{ _links?:{ allowedValues?:unknown } } }> }[];
  definesAllowedValues():boolean;
}

describe('QueryFilterInstanceSchemaResource', () => {
  describe('definesAllowedValues', () => {
    it('checks object-shaped dependency maps', () => {
      const schema = Object.create(QueryFilterInstanceSchemaResource.prototype) as SchemaWithAllowedValuesCheck;

      Object.defineProperty(schema, '_dependencies', {
        value: [
          {
            dependencies: {
              '/api/v3/queries/operators/=': {},
              '/api/v3/queries/operators/!*': {
                values: {
                  _links: {
                    allowedValues: {
                      href: '/api/v3/example',
                    },
                  },
                },
              },
            },
          },
        ],
      });

      expect(schema.definesAllowedValues()).toBe(true);
    });
  });
});
