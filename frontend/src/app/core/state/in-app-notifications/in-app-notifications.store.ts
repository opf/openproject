import { EntityStore, StoreConfig } from '@datorama/akita';
import { INotification } from './in-app-notification.model';
import { ResourceState, createInitialResourceState } from 'core-app/core/state/resource-store';

export interface InAppNotificationsState extends ResourceState<INotification> {
}

@StoreConfig({ name: 'in-app-notifications' })
export class InAppNotificationsStore extends EntityStore<InAppNotificationsState> {
  constructor() {
    super(createInitialResourceState());
  }
}
