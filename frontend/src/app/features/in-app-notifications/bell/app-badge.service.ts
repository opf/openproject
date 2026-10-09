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

import { Injectable, inject } from '@angular/core';
import { distinctUntilChanged } from 'rxjs/operators';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { getMetaValue } from 'core-app/core/setup/globals/global-helpers';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';

const BADGE_LIMIT = 99;
const INSTALLED_APP_BACKGROUND_FACTOR = 3;
const BROWSER_TAB_BACKGROUND_FACTOR = 10;

@Injectable({ providedIn: 'root' })
export class AppBadgeService {
  private readonly ianBell = inject(IanBellService);
  private readonly configuration = inject(ConfigurationService);

  initialize():void {
    if (!this.enabled) {
      return;
    }

    if (getMetaValue('current_user', 'loggedIn') !== 'true') {
      this.clear();
      return;
    }

    this.ianBell.unread$
      .pipe(distinctUntilChanged())
      .subscribe((count) => {
        if (count === 0) {
          this.clear();
        } else if (count > 0 && Number.isFinite(count)) {
          this.call((nav) => nav.setAppBadge(Math.min(count, BADGE_LIMIT)));
        }
      });
  }

  get backgroundPollingFactor():number {
    return this.enabled && this.runsAsInstalledApp
      ? INSTALLED_APP_BACKGROUND_FACTOR
      : BROWSER_TAB_BACKGROUND_FACTOR;
  }

  private get enabled():boolean {
    return this.configuration.activeFeatureFlags.includes('progressiveWebApp') && 'setAppBadge' in navigator;
  }

  private get runsAsInstalledApp():boolean {
    return window.matchMedia('(display-mode: standalone)').matches;
  }

  private clear():void {
    this.call((nav) => nav.clearAppBadge());
  }

  // Browsers that expose the API outside an installed app (Safari) reject the call instead of ignoring it.
  private call(action:(nav:Navigator) => Promise<void>):void {
    try {
      action(navigator).catch(() => undefined);
    } catch {
      // Unsupported environment; the badge is a progressive enhancement.
    }
  }
}
