import { Injectable } from '@angular/core';

import { Query } from '@datorama/akita';
import { map } from 'rxjs/operators';
import { Observable } from 'rxjs';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { UserPreferencesModel } from 'core-app/features/user-preferences/state/user-preferences.model';
import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

@Injectable()
export class UserPreferencesQuery extends Query<UserPreferencesModel> {
  notificationSettings$ = this.select('notifications');

  notificationsGroupedByProject$:Observable<{ [key:string]:NotificationSetting[] }> = this
    .notificationSettings$
    .pipe(
      map((notifications) => notifications.filter((setting) => setting.channel === 'in_app' && setting._links.project.href)),
      map((notifications) => _.groupBy(notifications, (setting) => setting._links.project.title)),
    );

  /** Notification settings grouped by Project */
  notificationsForGlobal$:Observable<NotificationSetting|undefined> = this
    .notificationSettings$
    .pipe(
      map((notifications) => notifications.find((setting) => setting.channel === 'in_app' && setting._links.project.href === null)),
    );

  projectNotifications$ = this
    .notificationSettings$
    .pipe(
      map((settings) => settings.filter((notification) => notification._links.project.href !== null)),
    );

  /** Selected projects */
  selectedProjects$ = this
    .notificationSettings$
    .pipe(
      map((notifications) => (
        new Set(notifications.map((setting) => setting._links.project?.href))
      )),
    );

  preferences$ = this.select();

  constructor(protected store:UserPreferencesStore) {
    super(store);
  }
}
