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

import { Injectable } from '@angular/core';
import { tap } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { ID } from '@datorama/akita';

import {
  markNotificationsAsRead,
  markNotificationsAsReadByFilters,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { InAppNotificationsStore } from 'core-app/core/state/in-app-notifications/in-app-notifications.store';
import {
  ResourceStore,
  ResourceStoreService,
} from 'core-app/core/state/resource-store.service';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

@EffectHandler
@Injectable()
export class InAppNotificationsResourceService extends ResourceStoreService<INotification> {
  @InjectField() actions$:ActionsService;

  update(id:ID, inAppNotification:Partial<INotification>):void {
    this.store.update(id, inAppNotification);
  }

  markAsRead(notifications:ID[]):Observable<unknown> {
    return this
      .apiV3Service
      .notifications
      .markAsReadByIds(notifications)
      .pipe(
        tap(() => {
          this.store.update(notifications, { readIAN: true });
        }),
      );
  }

  /**
   * Mark the given notification IDs as read through the API.
   */
  @EffectCallback(markNotificationsAsRead)
  private markNotificationsAsRead(action:ReturnType<typeof markNotificationsAsRead>) {
    this
      .markAsRead(action.notifications)
      .subscribe(() => (
        this.actions$.dispatch(notificationsMarkedRead({ ...action, all: false }))
      ));
  }

  @EffectCallback(markNotificationsAsReadByFilters)
  private markNotificationsAsReadByFilters(action:ReturnType<typeof markNotificationsAsReadByFilters>) {
    return this
      .apiV3Service
      .notifications
      .markAsReadByFilter(action.filters)
      .subscribe(() => {
        this.actions$.dispatch(notificationsMarkedRead({ origin: action.origin, notifications: [], all: true }));
      });
  }

  protected createStore():ResourceStore<INotification> {
    return new InAppNotificationsStore();
  }

  protected basePath():string {
    return this.apiV3Service.notifications.path;
  }
}
