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

import { samePosition, type FocusPosition } from './focus-position';

/**
 * Where keyboard focus logically is in the table: the position, the last position the user chose,
 * and the cell a Tab walk through its controls started from. Landing ends any walk.
 */
export class FocusCursor {
  private current:FocusPosition|null = null;

  private user:FocusPosition|null = null;

  private walk:FocusPosition|null = null;

  constructor(private readonly paint:(position:FocusPosition) => void) {}

  public get position():FocusPosition|null {
    return this.current;
  }

  public get userPosition():FocusPosition|null {
    return this.user;
  }

  public get walkOrigin():FocusPosition|null {
    return this.walk;
  }

  public land(position:FocusPosition, { user, paint }:{ user:boolean, paint:boolean }):void {
    this.walk = null;
    this.current = position;
    if (user) this.user = position;
    if (paint) this.paint(position);
  }

  /** Takes the walk origin as the position while focus rests on one of its controls. */
  public follow(origin:FocusPosition):void {
    this.current = origin;
    this.user = origin;
  }

  public noteUserMove(position:FocusPosition):void {
    this.user = position;
  }

  public reconcile(position:FocusPosition|null):void {
    this.current = position;
  }

  public startWalk(origin:FocusPosition):void {
    this.walk = origin;
  }

  public clearWalk():void {
    this.walk = null;
  }

  public userMovedSince(position:FocusPosition|null):boolean {
    return !samePosition(this.user, position);
  }
}
