import { Injectable } from '@angular/core';
import { QueryEntity } from '@datorama/akita';
import { map } from 'rxjs/operators';
import { InAppNotificationsStore, InAppNotificationsState } from './in-app-notifications.store';

@Injectable({ providedIn: 'root' })
export class InAppNotificationsQuery extends QueryEntity<InAppNotificationsState> {
  /** Get the number of unread items */
  unreadCount$ = this.select('unreadCount');

  /** Do we have any unread items? */
  hasUnread$ = this.unreadCount$.pipe(map((count) => count > 0));

  /** Get the unread items */
  unread$ = this.selectAll({
    filterBy: ({ readIAN }) => !readIAN,
  });

  /** Get all items that shall be kept in the notification center */
  keep$ = this.selectAll({
    filterBy: ({ keep }) => !!keep,
  });

  /** Do we have any notification that shall be visible the notification center? */
  hasNotifications$ = this.selectCount().pipe(map((count) => count > 0));

  activeFacet$ = this.select('activeFacet');

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
