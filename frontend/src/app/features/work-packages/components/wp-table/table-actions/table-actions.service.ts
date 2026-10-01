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

import { Injectable, Injector, inject } from '@angular/core';
import {
  OpTableActionFactory,
} from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { OpDetailsTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/details-table-action';
import { OpContextMenuTableAction } from 'core-app/features/work-packages/components/wp-table/table-actions/actions/context-menu-table-action';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

@Injectable()
export class OpTableActionsService {
  private readonly injector = inject(Injector);


  /**
   * Actions currently registered
   */
  private actions:OpTableActionFactory[] = [
    (injector, workPackage) => new OpDetailsTableAction(injector, workPackage),
    (injector, workPackage) => new OpContextMenuTableAction(injector, workPackage),
  ];

  /**
   * Replace the actions with a different set
   */
  public setActions(...actions:OpTableActionFactory[]) {
    this.actions = actions;
  }

  /**
   * Render actions for the given work package.
   * @param {WorkPackageResource} workPackage
   */
  public render(workPackage:WorkPackageResource):HTMLElement[] {
    const built = this.actions.map((factory) => factory(this.injector, workPackage).buildElement());
    return built.filter((x):x is NonNullable<typeof x> => Boolean(x));
  }
}
