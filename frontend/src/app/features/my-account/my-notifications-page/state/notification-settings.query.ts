import { Injectable } from '@angular/core';

import { NotificationSettingsState, NotificationSettingsStore } from './notification-settings.store';
import { Query } from "@datorama/akita";

@Injectable()
export class NotificationSettingsQuery extends Query<NotificationSettingsState> {
  /** All notification settings */
  notificationSettings$ = this.select('notifications');

  constructor(protected store:NotificationSettingsStore) {
    super(store);
  }
}
