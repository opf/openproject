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
import { filter } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { getMetaValue } from 'core-app/core/setup/globals/global-helpers';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

type WorkerMessage = { type:'reconcile' }|{ type:'account'; userId:string };

@Injectable({ providedIn: 'root' })
export class BrowserNotificationSyncService {
  private readonly ianBell = inject(IanBellService);
  private readonly configuration = inject(ConfigurationService);

  initialize():void {
    if (!this.available || !this.flagEnabled) {
      return;
    }

    if (getMetaValue('current_user', 'loggedIn') !== 'true') {
      this.requestReconcile();
      return;
    }

    const userId = getMetaValue('current_user', 'id', null);
    if (userId) {
      void this.post({ type: 'account', userId }).catch(() => undefined);
    }

    this.ianBell.loadedUnread$
      .pipe(filter((count) => count >= 0))
      .subscribe(() => this.requestReconcile());
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

  private requestReconcile():void {
    void this.post({ type: 'reconcile' }).catch(() => undefined);
  }

  private async post(message:WorkerMessage):Promise<void> {
    if (!this.permitted) {
      return;
    }

    const registration = await navigator.serviceWorker.ready;
    registration.active?.postMessage(message);
  }
}
