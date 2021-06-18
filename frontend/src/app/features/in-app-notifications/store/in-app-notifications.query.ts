import { Injectable } from '@angular/core';
import { QueryEntity } from '@datorama/akita';
import { InAppNotificationsStore, InAppNotificationsState } from './in-app-notifications.store';
import { map } from "rxjs/operators";

@Injectable({ providedIn: 'root' })
export class InAppNotificationsQuery extends QueryEntity<InAppNotificationsState> {

  /** Get the number of unread items */
  unreadCount$ = this.select('count');

  /** Do we have any unread items? */
  hasUnread$ = this.unreadCount$.pipe(map(count => count > 0));

  /** Get the unread items */
  unread$ = this.selectAll({
    filterBy: ({ read }) => !read
  });

  constructor(protected store:InAppNotificationsStore) {
    super(store);
  }

}
