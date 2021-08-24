import { Injectable } from '@angular/core';
import { EntityState, EntityStore, StoreConfig } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export interface InAppNotificationsState extends EntityState<InAppNotification> {
  /** The entities in the store might not all be unread so we keep separate count */
  unreadCount:number;
  /** Number of elements not showing after max values loaded */
  notLoaded:number;
  activeFacet:string;
  activeFilters:ApiV3ListFilter[];
  expanded:boolean;
}

export function createInitialState():InAppNotificationsState {
  return {
    unreadCount: 0,
    notLoaded: 0,
    activeFacet: 'unread',
    activeFilters: [],
    expanded: false,
  };
}

@Injectable()
@StoreConfig({ name: 'in-app-notifications' })
export class InAppNotificationsStore extends EntityStore<InAppNotificationsState> {
  constructor() {
    super(createInitialState());
  }
}
