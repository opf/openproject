import { Injectable } from '@angular/core';
import { EntityState, EntityStore, StoreConfig } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';

export interface InAppNotificationsState extends EntityState<InAppNotification> {}

@Injectable({ providedIn: 'root' })
@StoreConfig({ name: 'in-app-notifications' })
export class InAppNotificationsStore extends EntityStore<InAppNotificationsState> {
}
