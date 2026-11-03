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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { concatMap, from } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { getMetaValue } from 'core-app/core/setup/globals/global-helpers';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

const TAG_PREFIX = 'openproject-';
const MORE_TAG = 'openproject-more';

interface PushSummary {
  count:number;
  groups?:{ tag:string }[];
  more?:{ count:number }|null;
}

@Injectable({ providedIn: 'root' })
export class BrowserNotificationSyncService {
  private readonly ianBell = inject(IanBellService);
  private readonly configuration = inject(ConfigurationService);
  private readonly pathHelper = inject(PathHelperService);

  initialize():void {
    if (!this.available || !this.flagEnabled || getMetaValue('current_user', 'loggedIn') !== 'true') {
      return;
    }

    this.ianBell.loadedUnread$
      .pipe(concatMap((count) => from(this.reconcile(count).catch(() => undefined))))
      .subscribe();
  }

  private get available():boolean {
    return 'serviceWorker' in navigator && 'Notification' in window;
  }

  private get permitted():boolean {
    return Notification.permission === 'granted';
  }

  private get flagEnabled():boolean {
    return this.configuration.activeFeatureFlags.includes('progressiveWebApp');
  }

  private async reconcile(count:number):Promise<void> {
    if (count < 0 || !this.permitted) {
      return;
    }

    const registration = await navigator.serviceWorker.getRegistration();
    if (!registration) {
      return;
    }

    const open = await this.openNotifications(registration);
    if (open.length === 0) {
      return;
    }

    if (count === 0) {
      open.forEach((notification) => notification.close());
      return;
    }

    const keep = await this.tagsToKeep();
    if (!keep) {
      return;
    }

    // Only tags seen before the fetch are closed, so a notification a push showed meanwhile survives.
    const seen = new Set(open.map((notification) => notification.tag));
    (await this.openNotifications(registration))
      .filter((notification) => seen.has(notification.tag) && !keep.has(notification.tag))
      .forEach((notification) => notification.close());
  }

  private async openNotifications(registration:ServiceWorkerRegistration):Promise<Notification[]> {
    const notifications = await registration.getNotifications();
    return notifications.filter((notification) => notification.tag.startsWith(TAG_PREFIX));
  }

  private async tagsToKeep():Promise<Set<string>|undefined> {
    const response = await fetch(`${this.pathHelper.appBasePath}/push-notification`, {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
      cache: 'no-store',
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) {
      return undefined;
    }

    const summary = await response.json() as PushSummary;
    const keep = new Set((summary.groups ?? []).map((group) => group.tag));
    if (summary.more) {
      keep.add(MORE_TAG);
    }
    return keep;
  }
}
