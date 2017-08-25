// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++


import {opServicesModule} from '../../angular-modules';
import {WorkPackageTableColumns} from '../wp-fast-table/wp-table-columns';

export class WorkPackageResizerService {

  constructor() {
    console.log('Service constructor');
  }

  private printTestComment() {
    console.log('TEST COMMENT');
  }

  private changeTimelineWidthOnColumnCountChange(columns:WorkPackageTableColumns, table:HTMLElement, timeline:HTMLElement) {
    console.log('Service function');

    const colCount = columns.current.length;
    if (colCount === 0) {
      table.style.flex = `0 1 45px`;
      timeline.style.flex = `1 1`;
    } else if (colCount === 1) {
      table.style.flex = `1 1`;
      timeline.style.flex = `4 1`;
    } else if (colCount === 2) {
      table.style.flex = `1 1`;
      timeline.style.flex = `3 1`;
    } else if (colCount === 3) {
      table.style.flex = `1 1`;
      timeline.style.flex = `2 1`;
    } else if (colCount === 4) {
      table.style.flex = `2 1`;
      timeline.style.flex = `3 1`;
    }
  }
}

opServicesModule.service('wpResizer', WorkPackageResizerService);
