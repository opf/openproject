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
import { workPackageIdFrom } from './header-button.controller';

describe('AI Assistance header button', () => {
  describe('workPackageIdFrom', () => {
    it('reads the full view', () => {
      expect(workPackageIdFrom('/projects/demo/work_packages/2/activity')).toBe('2');
      expect(workPackageIdFrom('/work_packages/42')).toBe('42');
    });

    it('prefers the split view of a list, a board or a calendar', () => {
      expect(workPackageIdFrom('/projects/demo/work_packages/details/8')).toBe('8');
      expect(workPackageIdFrom('/projects/demo/boards/3/details/9/overview')).toBe('9');
    });

    it('reads semantic ids', () => {
      expect(workPackageIdFrom('/projects/demo/work_packages/PROJ-7/activity')).toBe('PROJ-7');
    });

    it('finds nothing on other pages', () => {
      expect(workPackageIdFrom('/projects/demo/work_packages')).toBeNull();
      expect(workPackageIdFrom('/projects/demo/work_packages/new')).toBeNull();
      expect(workPackageIdFrom('/my/page')).toBeNull();
    });
  });
});
