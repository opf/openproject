import { Injectable } from '@angular/core';
import { EntityState, EntityStore, StoreConfig } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';

export interface InAppNotificationsState extends EntityState<InAppNotification> {
  /** The entities in the store might not all be unread so we keep separate count */
  unreadCount:number;
  activeFacet:string;
  expanded:boolean;
}

export function createInitialState():InAppNotificationsState {
  return {
    unreadCount: 0,
    notShowing: 0,
    activeFacet: 'unread',
    expanded: false,
  };
}

@Injectable({ providedIn: 'root' })
@StoreConfig({ name: 'in-app-notifications' })
export class InAppNotificationsStore extends EntityStore<InAppNotificationsState> {
  constructor() {
    super(createInitialState());
  }
}
