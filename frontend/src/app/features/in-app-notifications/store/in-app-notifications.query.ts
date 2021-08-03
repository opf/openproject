import { Injectable } from '@angular/core';
import { QueryEntity } from '@datorama/akita';
import { map, switchMap } from 'rxjs/operators';
import { NEVER, Observable, throwError } from 'rxjs';
import {
  InAppNotificationsState,
  InAppNotificationsStore,
} from './in-app-notifications.store';
import { InAppNotification } from 'core-app/features/in-app-notifications/store/in-app-notification.model';

@Injectable({ providedIn: 'root' })
export class InAppNotificationsQuery extends QueryEntity<InAppNotificationsState> {
  /** Select the active filter facet */
  activeFacet$ = this.select('activeFacet');

  /** Get the faceted items */
  faceted$ = this.activeFacet$
    .pipe(
      switchMap((facet) => {
        switch (facet) {
          case 'unread':
            return this.unreadOrKept$;
          case 'all':
            return this.selectAll();
        }

        return throwError(new Error(`Invalid facet ${facet}`));
      })
    )

  /** Notifications grouped by resource */
  aggregatedNotifications$:Observable<{ [key:string]:InAppNotification[] }> = this
    .faceted$
    .pipe(
      map((notifications) => (
        _.groupBy(notifications, (notification) => notification._links.resource?.href || 'none')
      )),
    );

  /** Get the number of unread items */
  unreadCount$ = this.select('unreadCount');

  /** Do we have any unread items? */
  hasUnread$ = this.unreadCount$.pipe(map((count) => count > 0));

  /** Get the unread items */
  unread$ = this.selectAll({
    filterBy: ({ readIAN }) => !readIAN,
  });

  /** Get all items that shall be kept in the notification center */
  unreadOrKept$ = this.selectAll({
    filterBy: ({ readIAN, keep }) => !readIAN || !!keep,
  });

  /** Do we have any notification that shall be visible the notification center? */
  hasNotifications$ = this.selectCount().pipe(map((count) => count > 0));

  /** Determine whether the pageSize is not sufficient to load all notifcations */
  hasMoreThanPageSize$ = this
    .select()
    .pipe(
      map(({ notShowing }) => notShowing > 0),
    );

  constructor(protected store:InAppNotificationsStore) {
    super(store);
  }
}
