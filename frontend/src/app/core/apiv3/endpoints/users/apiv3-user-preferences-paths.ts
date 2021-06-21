//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++

import { UserResource } from "core-app/features/hal/resources/user-resource";
import { MultiInputState } from "reactivestates";
import { CachableAPIV3Resource } from "core-app/core/apiv3/cache/cachable-apiv3-resource";
import { StateCacheService } from "core-app/core/apiv3/cache/state-cache.service";
import { APIv3ResourcePath } from "core-app/core/apiv3/paths/apiv3-resource";
import { NotificationSetting } from "core-app/features/my-account/my-notifications-page/state/notification-setting.model";
import { Observable } from "rxjs";
import { InjectField } from "core-app/shared/helpers/angular/inject-field.decorator";
import { HttpClient } from "@angular/common/http";

export interface UserPreference {
  [key:string]:unknown;
  notifications:NotificationSetting[];
}

export class Apiv3UserPreferencesPaths extends APIv3ResourcePath<UserPreference> {
  @InjectField() http:HttpClient;


  /**
   * Perform a request to the backend to load preferences
   */
  public get():Observable<UserPreference> {
    return this
      .http
      .get<UserPreference>(
        this.path,
      );
  }

  /**
   * Perform a request to update preferences
   */
  public patch(payload:Partial<UserPreference>):Observable<UserPreference> {
    return this
      .http
      .patch<UserPreference>(
        this.path,
        payload,
        { withCredentials: true, responseType: 'json' }
      );
  }
}
