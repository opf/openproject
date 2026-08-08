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

export class GridArea {
  private storedGuid:string;

  public startRow:number;

  public endRow:number;

  public startColumn:number;

  public endColumn:number;

  constructor(startRow:number, endRow:number, startColumn:number, endColumn:number) {
    this.startRow = startRow;
    this.endRow = endRow;
    this.startColumn = startColumn;
    this.endColumn = endColumn;
  }

  public get gridStartRow() {
    return this.startRow * 2;
  }

  public get gridEndRow() {
    return this.endRow * 2 - 1;
  }

  public get gridStartColumn() {
    return this.startColumn * 2;
  }

  public get gridEndColumn() {
    return this.endColumn * 2 - 1;
  }

  public get guid():string {
    if (!this.storedGuid) {
      this.storedGuid = this.newGuid();
    }

    return this.storedGuid;
  }

  private newGuid() {
    function s4() {
      return Math.floor((1 + Math.random()) * 0x10000)
        .toString(16)
        .substring(1);
    }
    return `${s4() + s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
  }
}
