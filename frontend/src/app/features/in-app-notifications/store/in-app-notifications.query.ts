import { Injectable } from '@angular/core';
import { QueryEntity } from '@datorama/akita';
import { InAppNotificationsStore, InAppNotificationsState } from './in-app-notifications.store';

@Injectable({ providedIn: 'root' })
export class InAppNotificationsQuery extends QueryEntity<InAppNotificationsState> {

  /** Get the number of unread items */
  unreadCount$ = this.selectCount(item => !item.read);

  /** Get the unread items */
  unread$ = this.selectAll({
    filterBy: ({ read }) => !read
  });

  constructor(protected store:InAppNotificationsStore) {
    super(store);
  }

}
