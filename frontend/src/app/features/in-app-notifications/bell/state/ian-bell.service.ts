import { Injectable } from '@angular/core';
import { IanBellStore } from './ian-bell.store';
import { InAppNotificationsService } from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { IAN_FACET_FILTERS } from 'core-app/features/in-app-notifications/center/state/ian-center.store';
import {
  map,
  tap,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { IanBellQuery } from 'core-app/features/in-app-notifications/bell/state/ian-bell.query';
import {
  EffectCallback,
  EffectHandler,
} from 'core-app/core/state/effects/effect-handler.decorator';
import { notificationsMarkedRead } from 'core-app/core/state/in-app-notifications/in-app-notifications.actions';
import { ActionsService } from 'core-app/core/state/actions/actions.service';

@Injectable()
@EffectHandler
export class IanBellService {
  readonly id = 'ian-center';

  readonly store = new IanBellStore();

  readonly query = new IanBellQuery(this.store);

  unread$ = this.query.select('totalUnread');

  constructor(
    readonly actions$:ActionsService,
    readonly ianService:InAppNotificationsService,
  ) {
  }

  fetchUnread():Observable<number> {
    return this.ianService
      .fetchNotifications({ filters: IAN_FACET_FILTERS.unread, pageSize: 0 })
      .pipe(
        map((result) => result.total),
        tap((count) => {
          this.store.update({ totalUnread: count });
        }),
      );
  }

  @EffectCallback(notificationsMarkedRead)
  private reloadOnNotificationRead(action:ReturnType<typeof notificationsMarkedRead>) {
    this.store.update(({ totalUnread }) => ({ totalUnread: totalUnread - action.notifications.length }));
  }
}
