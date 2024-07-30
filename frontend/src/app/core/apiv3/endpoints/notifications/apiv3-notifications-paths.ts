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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { ID } from '@datorama/akita';

import { ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { ApiV3NotificationPaths } from 'core-app/core/apiv3/endpoints/notifications/apiv3-notification-paths';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';

export class ApiV3NotificationsPaths
  extends ApiV3ResourceCollection<INotification, ApiV3NotificationPaths> {
  @InjectField() http:HttpClient;

  constructor(
    protected apiRoot:ApiV3Service,
    protected basePath:string,
  ) {
    super(apiRoot, basePath, 'notifications', ApiV3NotificationPaths);
  }

  public facet(facet:string, params?:ApiV3ListParameters):Observable<IHALCollection<INotification>> {
    if (facet === 'unread') {
      return this.unread(params);
    }
    return this.list(params);
  }

  /**
   * Load a list of events with a given list parameter filter
   * @param params
   */
  public list(params?:ApiV3ListParameters):Observable<IHALCollection<INotification>> {
    return this
      .http
      .get<IHALCollection<INotification>>(this.path + listParamsString(params));
  }

  public listPath(params?:ApiV3ListParameters):string {
    return this.path + listParamsString(params);
  }

  /**
   * Load unread events
   */
  public unread(additional?:ApiV3ListParameters):Observable<IHALCollection<INotification>> {
    const unreadFilter:ApiV3ListFilter = ['readIAN', '=', false];
    const filters = [
      ...(additional?.filters ? additional.filters : []),
      unreadFilter,
    ];
    const params:ApiV3ListParameters = {
      ...additional,
      filters,
    };

    return this.list(params);
  }

  /**
   * Mark all notifications as read
   * @param ids
   */
  public markAsReadByIds(ids:Array<ID>):Observable<unknown> {
    return this
      .http
      .post(
        `${this.path}/read_ian${listParamsString({ filters: [['id', '=', ids.map((id) => id.toString())]] })}`,
        {},
        {
          withCredentials: true,
          responseType: 'json',
        },
      );
  }

  public markAsReadByFilter(filters:ApiV3ListFilter[]):Observable<unknown> {
    return this.http.post(
      `${this.path}/read_ian${(listParamsString({ filters: filters.map((f) => [f[0], f[1], f[2]]) }))}`,
      {},
      {
        withCredentials: true,
        responseType: 'json',
      },
    );
  }
}
