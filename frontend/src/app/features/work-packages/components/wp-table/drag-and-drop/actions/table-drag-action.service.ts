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

import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { Injector } from '@angular/core';

export class TableDragActionService {
  /**
   * Initialize an action service in the given isolated query space
   * @param querySpace The isolated query space for this table
   * @param injector The hierarchical injector for this table
   */
  constructor(readonly querySpace:IsolatedQuerySpace,
    readonly injector:Injector) {
  }

  /**
   * Determine whether the service applies for the given
   * query spaces.
   */
  public get applies():boolean {
    return true;
  }

  /**
   * Perform a post-order update
   */
  public onNewOrder(newOrder:string[]):void {
  }

  /**
   * Returns whether the given work package is movable
   */
  public canPickup(workPackage:WorkPackageResource):boolean {
    return true;
  }

  /**
   * Perform the respective action for the drop that just happened
   *
   * @param workPackage
   * @param target
   * @param source
   * @param sibling
   */
  public handleDrop(workPackage:WorkPackageResource, el:HTMLElement):Promise<unknown> {
    return Promise.resolve(undefined);
  }
}
