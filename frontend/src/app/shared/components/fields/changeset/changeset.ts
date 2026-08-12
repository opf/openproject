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

export interface ChangeItem {
  from:unknown;
  to:unknown;
}
export type ChangeMap = Record<string, ChangeItem>;

export class Changeset {
  private changes:ChangeMap = {};

  /**
   * Return whether a change value exist for the given attribute key.
   * @param {string} key
   * @return {boolean}
   */
  public contains(key:string) {
    return this.changes.hasOwnProperty(key);
  }

  /**
   * Get changed attribute names
   * @returns {string[]}
   */
  public get changed():string[] {
    return Object.keys(this.changes);
  }

  /**
   * Returns the live set of the changes.
   */
  public get all():ChangeMap {
    return this.changes;
  }

  /**
   * Reset one or multiple changes
   * @param key
   */
  public reset(...keys:string[]) {
    keys.forEach((k) => {
      delete this.changes[k];
    });
  }

  /**
   * Reset the entire changeset
   */
  public clear():void {
    this.changes = {};
  }

  public set(key:string, value:unknown, pristineValue:unknown):void {
    this.changes[key] = {
      from: pristineValue,
      to: value,
    };
  }

  /**
   * Get a change item for the given key, if any
   * @param key
   */
  public getItem(key:string):ChangeItem|undefined {
    return this.changes[key];
  }

  /**
   * Get a single value from the changeset
   * @param key
   */
  public getValue(key:string):unknown|undefined {
    return this.getItem(key)?.to;
  }

  /**
   * Get a single pristine value from the changeset
   * @param key
   */
  public getPristine(key:string):unknown|undefined {
    return this.changes[key]?.from;
  }
}
