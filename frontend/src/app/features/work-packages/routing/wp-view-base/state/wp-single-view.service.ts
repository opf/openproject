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
import { WpSingleViewStore } from './wp-single-view.store';
import {
  filter,
  map,
  switchMap,
  take,
} from 'rxjs/operators';
import { InAppNotificationsResourceService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import {
  ApiV3ListFilter,
  ApiV3ListParameters,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import {
  centerUpdatedInPlace,
  markNotificationsAsRead,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { Query } from '@datorama/akita';

@Injectable()
@EffectHandler
export class WpSingleViewService {
  readonly actions$ = inject(ActionsService);
  readonly currentUser$ = inject(CurrentUserService);
  private resourceService = inject(InAppNotificationsResourceService);

  id = 'WorkPackage Activity Store';

  protected store = new WpSingleViewStore();

  protected query = new Query(this.store);

  selectNotifications$ = this
    .query
    .select((state) => state.notifications.filters)
    .pipe(
      filter((filters) => filters.length > 0),
      switchMap((filters) => this.resourceService.collection({ filters })),
    );

  selectNotificationsCount$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => notifications.length),
    );

  nonDateAlertNotificationsCount$ = this
    .selectNotifications$
    .pipe(
      map((notifications) => notifications.filter((notification) => notification.reason !== 'dateAlert')),
      map((notifications) => notifications.length),
    );

  hasNotifications$ = this
    .selectNotificationsCount$
    .pipe(
      map((count) => count > 0),
    );

  get params():ApiV3ListParameters {
    return { filters: this.query.getValue().notifications.filters };
  }

  setFilters(workPackageId:string):void {
    const filters:ApiV3ListFilter[] = [
      ['readIAN', '=', false],
      ['resourceId', '=', [workPackageId]],
      ['resourceType', '=', ['WorkPackage']],
    ];

    this.store.update(({ notifications }) => (
      {
        notifications: {
          ...notifications,
          filters,
        },
      }
    ));

    this.reload();
  }

  markAllAsRead():void {
    this
      .resourceService
      .collection({ filters: this.store.getValue().notifications.filters })
      .pipe(
        take(1),
      )
      .subscribe((collection) => {
        this.actions$.dispatch(
          markNotificationsAsRead({ origin: this.id, notifications: collection.map((el) => el.id) }),
        );
      });
  }

  reload() {
    this
      .currentUser$
      .isLoggedIn$
      .pipe(
        take(1),
        filter((loggedIn) => loggedIn),
        switchMap(() => this.resourceService.fetchCollection(this.params)),
      )
      .subscribe();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead() {
    this.reload();
  }

  /**
   * Reload after notifications were successfully marked as read
   */
  @EffectCallback(centerUpdatedInPlace)
  private reloadOnCenterUpdate() {
    this.reload();
  }
}
