import { Injectable } from '@angular/core';

import { NotificationSettingsState, NotificationSettingsStore } from './notification-settings.store';
import { Query } from "@datorama/akita";
import { filter, map } from "rxjs/operators";
import { NotificationSetting } from "core-app/features/my-account/my-notifications-page/state/notification-setting.model";
import { Observable } from "rxjs";

@Injectable()
export class NotificationSettingsQuery extends Query<NotificationSettingsState> {
  /** All notification settings */
  notificationSettings$ = this.select('notifications');

  /** Notification settings grouped by Project */
  groupedByProject$:Observable<{ [key:string]:NotificationSetting[] }> = this
    .notificationSettings$
    .pipe(
      map(notifications => _.groupBy(notifications, setting => setting._links.project.href || 'global'))
    );

  projectSettings$ = this
    .notificationSettings$
    .pipe(
      map(settings => settings.filter(notification => notification._links.project.href !== null))
    );

  constructor(protected store:NotificationSettingsStore) {
    super(store);
  }
}
