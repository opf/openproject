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

import { Controller } from '@hotwired/stimulus';

const SHELL_CACHE_PREFIX = 'openproject-shell-';

export default class PwaServiceWorkerController extends Controller {
  static values = {
    url: String,
    scope: String,
    signedIn: { type: Boolean, default: true },
  };

  declare readonly urlValue:string;
  declare readonly scopeValue:string;
  declare readonly signedInValue:boolean;

  connect():void {
    if (!this.signedInValue) {
      this.clearShellCaches();
    }

    this.register();
  }

  private register():void {
    if (!('serviceWorker' in navigator) || !window.isSecureContext) {
      return;
    }

    try {
      navigator.serviceWorker
        .register(this.urlValue, { scope: this.scopeValue })
        .catch(() => undefined);
    } catch {
      // Registration is a progressive enhancement; the app works without it.
    }
  }

  private clearShellCaches():void {
    if (!('caches' in window)) {
      return;
    }

    try {
      void window.caches
        .keys()
        .then((names) => Promise.all(
          names
            .filter((name) => name.startsWith(SHELL_CACHE_PREFIX))
            .map((name) => window.caches.delete(name)),
        ))
        .catch(() => undefined);
    } catch {
      // Clearing is best effort; a later page load retries.
    }
  }
}
