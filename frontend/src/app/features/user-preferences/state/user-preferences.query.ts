//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { groupBy } from 'lodash-es';
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

  notificationsGroupedByProject$:Observable<Record<string, INotificationSetting[]>> = this
    .notificationSettings$
    .pipe(
      map((settings) => settings.filter((setting) => setting._links.project.href)),
      map((settings) => groupBy(settings, (setting) => setting._links.project.title)),
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
    );

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
