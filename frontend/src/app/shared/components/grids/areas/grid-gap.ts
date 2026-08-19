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

import { GridArea } from 'core-app/shared/components/grids/areas/grid-area';

export class GridGap extends GridArea {
  private type:'row'|'column';

  constructor(startRow:number, endRow:number, startColumn:number, endColumn:number, type:'row'|'column') {
    super(startRow, endRow, startColumn, endColumn);

    this.type = type;
  }

  public get gridStartRow() {
    if (this.isRow) {
      return this.startRow * 2 - 1;
    }
    return this.startRow * 2;
  }

  public get gridEndRow() {
    if (this.isRow) {
      return this.endRow * 2 - 2;
    }
    return this.endRow * 2 - 1;
  }

  public get gridStartColumn() {
    if (this.isRow) {
      return this.startColumn * 2;
    }
    return this.startColumn * 2 - 1;
  }

  public get gridEndColumn() {
    if (this.isRow) {
      return this.endColumn * 2 - 1;
    }
    return this.endColumn * 2 - 2;
  }

  public get isRow() {
    return this.type === 'row';
  }

  public get isColumn() {
    return this.type === 'column';
  }
}
