import { Injectable } from '@angular/core';

import { Query } from '@datorama/akita';
import {
  filter,
  map,
} from 'rxjs/operators';
import { Observable } from 'rxjs';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { IUserPreference } from 'core-app/features/user-preferences/state/user-preferences.model';
import { INotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export class UserPreferencesQuery extends Query<IUserPreference> {
  notificationSettings$ = this.select('notifications');

  notificationsGroupedByProject$:Observable<{ [key:string]:INotificationSetting[] }> = this
    .notificationSettings$
    .pipe(
      map((settings) => settings.filter((setting) => setting._links.project.href)),
      map((settings) => _.groupBy(settings, (setting) => setting._links.project.title)),
    );

  /** Notification settings grouped by Project */
  notificationsForGlobal$:Observable<INotificationSetting|undefined> = this
    .notificationSettings$
    .pipe(
      map((notifications) => notifications.find((setting) => setting._links.project.href === null)),
    );

  projectNotifications$ = this
    .notificationSettings$
    .pipe(
      map((settings) => settings.filter((setting) => setting._links.project.href !== null)),
    );

  globalNotification$ = this
    .notificationSettings$
    .pipe(
      map((settings) => settings.find((notification) => !notification._links.project.href)),
      filter((global) => !!global),
    ) as Observable<INotificationSetting>;

  /** Selected projects */
  selectedProjects$ = this
    .notificationSettings$
    .pipe(
      map((notifications) => (
        new Set(notifications.map((setting) => setting._links.project?.href))
      )),
    );

  /** All daily reminders settings */
  dailyReminders$ = this.select('dailyReminders');

  dailyRemindersEnabled$ = this
    .dailyReminders$
    .pipe(
      map((reminders) => reminders.enabled),
    );

  dailyRemindersTimes$ = this
    .dailyReminders$
    .pipe(
      map((reminders) => reminders.times),
    );

  preferences$ = this.select();

  constructor(protected store:UserPreferencesStore) {
    super(store);
  }
}
