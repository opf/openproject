import { Injectable } from '@angular/core';
import { EntityState, EntityStore, StoreConfig } from '@datorama/akita';
import { InAppNotification, NOTIFICATIONS_MAX_SIZE } from './in-app-notification.model';
import { ApiV3ListFilter } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';

export interface InAppNotificationsState extends EntityState<InAppNotification> {
  /** Number of elements not showing after max values loaded */
  notLoaded:number;
  pageSize:number;
  activeFacet:string;
  activeFilters:ApiV3ListFilter[];
  expanded:boolean;
}

export function createInitialState():InAppNotificationsState {
  return {
    notLoaded: 0,
    pageSize: NOTIFICATIONS_MAX_SIZE,
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
