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

import { describe, expect, it } from 'vitest';
import { boardInlineAddScope } from './board-inline-add-scope';

describe('boardInlineAddScope', () => {
  const manualSort = { manualSort: { operator: 'ow' as const, values: [] } };
  const project = { project: { operator: '=' as const, values: ['5'] } };
  const subprojectId = { subprojectId: { operator: '=' as const, values: ['7'] } };

  it('searches globally on a Basic column without project filters', () => {
    expect(boardInlineAddScope([manualSort], '1')).toEqual({ projectId: null, forwardedFilters: [] });
  });

  it('stays in the project and forwards project filters on a narrowed Basic column', () => {
    expect(boardInlineAddScope([manualSort, project], '1'))
      .toEqual({ projectId: '1', forwardedFilters: ['project', 'subprojectId'] });
  });

  it('forwards subprojectId alongside project on a Basic column', () => {
    expect(boardInlineAddScope([manualSort, project, subprojectId], '1').forwardedFilters)
      .toEqual(['project', 'subprojectId']);
  });

  it('stays in the project on a Basic column with only a subproject filter', () => {
    expect(boardInlineAddScope([manualSort, subprojectId], '1'))
      .toEqual({ projectId: '1', forwardedFilters: ['project', 'subprojectId'] });
  });

  it('forwards only subprojectId on an action column', () => {
    expect(boardInlineAddScope([{ status: { operator: '=', values: ['1'] } }, project], '1'))
      .toEqual({ projectId: '1', forwardedFilters: ['subprojectId'] });
  });
});
