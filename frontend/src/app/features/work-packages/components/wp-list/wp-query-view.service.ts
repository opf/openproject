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

import { Injectable, inject } from '@angular/core';
import { StateService } from '@uirouter/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { Observable } from 'rxjs';
import { IView } from 'core-app/core/state/views/view.model';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';

@Injectable()
export class WorkPackagesQueryViewService {
  protected $state = inject(StateService);
  protected apiV3Service = inject(ApiV3Service);


  create(query:QueryResource):Observable<IView> {
    if (!query.href) {
      throw new Error('Expected only queries that are created since an href is required');
    }

    return this
      .apiV3Service
      .views
      .post(
        {
          _links: {
            query: {
              href: query.href,
            },
          },
        },
        this.viewType,
      );
  }

  private get viewType() {
    // Check URL first for non-uiRouter pages (team_planners, calendars, boards).
    // $state.current.name may be stale from a previous router page after Turbo navigation.
    const { pathname } = window.location;
    if (pathname.includes('/team_planners')) { return 'team_planner'; }
    if (pathname.includes('/calendars')) { return 'work_packages_calendar'; }
    if (pathname.includes('/boards')) { return 'boards'; }

    // For uiRouter-managed pages, derive from state
    if (this.$state.includes('work-packages')) { return 'work_packages_table'; }
    if (this.$state.includes('bim')) { return 'bim'; }
    if (this.$state.includes('gantt')) { return 'gantt'; }

    // URL fallback for in case $state is stale after Turbo navigation
    if (pathname.includes('/work_packages')) { return 'work_packages_table'; }
    if (pathname.includes('/gantt')) { return 'gantt'; }
    if (pathname.includes('/bcf')) { return 'bim'; }

    throw new Error('Not on a path defined for query views');
  }
}
