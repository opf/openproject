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
import {
  catchError,
  map,
  skip,
  tap,
} from 'rxjs/operators';
import { EMPTY, Observable } from 'rxjs';

import {
  InAppNotificationsResourceService,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { IAN_FACET_FILTERS } from 'core-app/features/in-app-notifications/center/state/ian-center.store';
import { IanBellQuery } from 'core-app/features/in-app-notifications/bell/state/ian-bell.query';
import { EffectCallback, EffectHandler } from 'core-app/core/state/effects/effect-handler.decorator';
import {
  notificationCountIncreased,
  notificationCountChanged,
  notificationsMarkedRead,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { IanBellStore } from 'core-app/features/in-app-notifications/bell/state/ian-bell.store';

/**
 * The BellService is injected into root here (and the store is thus made global),
 * because we are dependent in many places on the information about how many notifications there are in total.
 * Instead of repeating these requests, we prefer to use the global store for now.
 */
@Injectable({ providedIn: 'root' })
@EffectHandler
export class IanBellService {
  readonly id = 'ian-bell';

  readonly store = new IanBellStore();

  readonly query = new IanBellQuery(this.store);

  unread$ = this.query.unread$;

  constructor(
    readonly actions$:ActionsService,
    readonly resourceService:InAppNotificationsResourceService,
  ) {
    this.query.unreadCountChanged$.subscribe((count) => {
      this.actions$.dispatch(notificationCountChanged({ origin: this.id, count }));
    });
    this.query.unreadCountIncreased$.pipe(skip(1)).subscribe((count) => {
      this.actions$.dispatch(notificationCountIncreased({ origin: this.id, count }));
    });
  }

  fetchUnread():Observable<number> {
    return this
      .resourceService
      .fetchCollection(
        { filters: IAN_FACET_FILTERS.unread, pageSize: 0 },
        { handleErrors: false },
      )
      .pipe(
        map((result) => result.total),
        tap(
          (count) => {
            this.store.update({ totalUnread: count });
          },
          (error) => {
            console.error('Failed to load notifications: %O', error);
            this.store.update({ totalUnread: -1 });
          },
        ),
        catchError(() => EMPTY),
      );
  }

  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    if (action.all) {
      this.fetchUnread().subscribe();
    } else {
      this.store.update(({ totalUnread }) => ({ totalUnread: totalUnread - action.notifications.length }));
    }
  }
}
