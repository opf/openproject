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

import { multiInput } from '@openproject/reactivestates';
import { BcfExtensionResource } from 'core-app/features/bim/bcf/api/extensions/bcf-extension.resource';
import { BcfApiService } from 'core-app/features/bim/bcf/api/bcf-api.service';
import {
  firstValueFrom,
  Observable,
} from 'rxjs';
import { map } from 'rxjs/operators';
import { Injectable, inject } from '@angular/core';

export type AllowedExtensionKey = keyof BcfExtensionResource;

@Injectable({ providedIn: 'root' })
export class BcfAuthorizationService {
  readonly bcfApi = inject(BcfApiService);

  // Poor mans caching to avoid repeatedly fetching from the backend.
  protected authorizationMap = multiInput<BcfExtensionResource>();

  /**
   * Returns an observable boolean whether the given action
   * is authorized in the project by using the project extensions.
   *
   * Ensures the extension is loaded only once per project
   *
   * @param projectIdentifier Project identifier to check permission in
   * @param extension The extension key to check for
   * @param action The desired action
   */
  public authorized$(projectIdentifier:string, extension:AllowedExtensionKey, action:string):Observable<boolean> {
    const state = this.authorizationMap.get(projectIdentifier);

    state.putFromPromiseIfPristine(() => firstValueFrom(
      this.bcfApi
        .projects.id(projectIdentifier)
        .extensions
        .get(),
    ));

    return state
      .values$()
      .pipe(
        map(
          (resource) => resource[extension] && resource[extension].includes(action),
        ),
      );
  }

  /**
   * One-time check to determine current allowed state.
   *
   * @param projectIdentifier Project identifier to check permission in
   * @param extension The extension key to check for
   * @param action The desired action
   */
  public isAllowedTo(projectIdentifier:string, extension:AllowedExtensionKey, action:string):Promise<boolean> {
    return firstValueFrom(this.authorized$(projectIdentifier, extension, action))
      .catch(() => false);
  }
}
