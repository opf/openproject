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

import { Injectable } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable, of } from 'rxjs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { catchError, map } from 'rxjs/operators';
import { FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

@Injectable({
  providedIn: 'root',
})
export class PermissionsService {
  constructor(
    private apiV3Service:ApiV3Service,
    private currentProjectService:CurrentProjectService,
  ) { }

  canInviteUsersToProject(projectId = this.currentProjectService.id!):Observable<boolean> {
    // TODO: Remove/Fix this typing issue
    const filters:[string, FilterOperator, string[]][] = [['id', '=', [projectId]]];

    return this.apiV3Service
      .memberships
      .available_projects
      .list({ filters })
      .pipe(
        map((collection) => !!collection.elements.length),
        catchError((error) => {
          console.error(error);
          return of(false);
        }),
      );
  }
}
