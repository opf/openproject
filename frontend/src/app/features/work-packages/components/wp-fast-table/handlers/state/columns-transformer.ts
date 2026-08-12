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
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { takeUntil } from 'rxjs/operators';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { WorkPackageTable } from '../../wp-fast-table';

export class ColumnsTransformer {
  @LazyInject() public querySpace:IsolatedQuerySpace;

  @LazyInject() public wpTableColumns:WorkPackageViewColumnsService;

  constructor(public readonly injector:Injector,
    public table:WorkPackageTable) {
    this.wpTableColumns
      .updates$()
      .pipe(
        takeUntil(this.querySpace.stopAllSubscriptions),
      )
      .subscribe(() => {
        if (table.originalRows.length > 0) {
          const t0 = performance.now();
          // Redraw the table section, ignore timeline
          table.redrawTable();

          const t1 = performance.now();

          debugLog(`column redraw took ${t1 - t0} milliseconds.`);
        }
      });
  }
}
