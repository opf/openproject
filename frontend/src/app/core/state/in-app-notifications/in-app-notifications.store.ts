import { EntityStore, StoreConfig } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';
import { CollectionState, createInitialCollectionState } from 'core-app/core/state/collection-store';

export interface InAppNotificationsState extends CollectionState<InAppNotification> {
}

@StoreConfig({ name: 'in-app-notifications' })
export class InAppNotificationsStore extends EntityStore<InAppNotificationsState> {
  constructor() {
    super(createInitialCollectionState());
  }
}
