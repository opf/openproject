// -- copyright
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

import { APIv3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable } from 'rxjs';
import { Apiv3ListParameters, listParamsString } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { InAppNotification } from 'core-app/features/in-app-notifications/store/in-app-notification.model';
import { Apiv3NotificationPaths } from 'core-app/core/apiv3/endpoints/notifications/apiv3-notification-paths';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { HttpClient } from '@angular/common/http';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ID } from '@datorama/akita';

export class Apiv3NotificationsPaths
  extends APIv3ResourceCollection<InAppNotification, Apiv3NotificationPaths> {
  @InjectField() http:HttpClient;

  constructor(protected apiRoot:APIV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'notifications', Apiv3NotificationPaths);
  }

  public facet(facet:string, params?:Apiv3ListParameters):Observable<IHALCollection<InAppNotification>> {
    if (facet === 'unread') {
      return this.unread(params);
    }
    return this.list(params);
  }

  /**
   * Load a list of events with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<IHALCollection<InAppNotification>> {
    return this
      .http
      .get<IHALCollection<InAppNotification>>(this.path + listParamsString(params));
  }

  /**
   * Load unread events
   */
  public unread(additional?:Apiv3ListParameters):Observable<IHALCollection<InAppNotification>> {
    const params:Apiv3ListParameters = {
      ...additional,
      filters: [['readIAN', '=', false]],
    };

    return this.list(params);
  }

  /**
   * Mark all notifications as read
   * @param ids
   */
  public markRead(ids:Array<ID>):Observable<unknown> {
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
}
