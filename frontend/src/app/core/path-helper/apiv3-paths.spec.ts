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

import { ApiV3Paths } from './apiv3-paths';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

function resource(source:object):HalResource {
  return source as unknown as HalResource;
}

function filtersOf(url:string|null):unknown[] {
  return JSON.parse(new URL(url!, 'http://localhost').searchParams.get('filters')!) as unknown[];
}

describe('ApiV3Paths#principals', () => {
  const paths = new ApiV3Paths('');

  it('restricts a saved post to the principals mentionable on its message', () => {
    const url = paths.principals(resource({ _type: 'Post', id: '7', project: { id: '3' } }), 'al');

    expect(filtersOf(url)).toContainEqual({ mentionable_on_message: { operator: '=', values: ['7'] } });
    expect(filtersOf(url)).toContainEqual({ name: { operator: '~', values: ['al'] } });
  });

  it('restricts a new post to the members of its project', () => {
    const url = paths.principals(resource({ _type: 'Post', id: null, project: { id: '3' } }), null);

    expect(filtersOf(url)).toContainEqual({ member: { operator: '=', values: ['3'] } });
  });

  it('keeps restricting a saved work package to its mentionable principals', () => {
    const url = paths.principals(resource({ _type: 'WorkPackage', id: '42', project: { id: '3' } }), null);

    expect(filtersOf(url)).toContainEqual({ mentionable_on_work_package: { operator: '=', values: ['42'] } });
  });

  it('offers no user mentions for other resources', () => {
    expect(paths.principals(resource({ _type: 'WikiPage', id: '1' }), null)).toBeNull();
  });
});
