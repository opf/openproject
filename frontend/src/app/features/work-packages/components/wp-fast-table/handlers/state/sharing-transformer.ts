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

import { Injector } from '@angular/core';
import { filter, map } from 'rxjs/operators';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';

export class SharingTransformer {
  public actions$ = this.injector.get(ActionsService);

  constructor(
    readonly injector:Injector,
    readonly table:WorkPackageTable,
  ) {
    this.actions$
      .ofType(shareModalUpdated)
      .pipe(
        map((action) => action.workPackageId),
        filter((id) => !!this.table.renderedRows.find((el:RenderedWorkPackage) => el.workPackageId === id)),
      )
      .subscribe(() => {
        this.actions$.dispatch(tableRefreshRequest());
      });
  }
}
