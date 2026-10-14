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

import { Controller } from '@hotwired/stimulus';
import { destroy, post } from '@rails/request.js';

interface KnownSubscription {
  endpoint:string;
  revokeUrl:string;
}

type State = 'unsupported'|'blocked'|'enabled'|'disabled'|'error';

const STATUS_KEYS:Record<State, string> = {
  unsupported: 'js.push_subscription.unsupported',
  blocked: 'js.push_subscription.blocked',
  enabled: 'js.push_subscription.enabled',
  disabled: 'js.push_subscription.disabled',
  error: 'js.push_subscription.error',
};

const REGISTRATION_TIMEOUT_MS = 5000;

function decodeBase64Url(value:string):Uint8Array<ArrayBuffer> {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
}

export default class PushSubscriptionController extends Controller {
  static values = {
    vapidPublicKey: String,
    createUrl: String,
    subscriptions: Array,
  };

  static targets = ['status', 'enable', 'disable'];

  declare readonly vapidPublicKeyValue:string;
  declare readonly createUrlValue:string;
  declare readonly subscriptionsValue:KnownSubscription[];
  declare readonly statusTarget:HTMLElement;
  declare readonly enableTarget:HTMLButtonElement;
  declare readonly disableTarget:HTMLButtonElement;

  private generation = 0;

  connect():void {
    this.setBusy(true);
    void this.sync();
  }

  private async sync():Promise<void> {
    this.generation += 1;
    const gen = this.generation;
    const current = () => gen === this.generation && this.element.isConnected;

    try {
      if (!this.supported()) {
        this.render('unsupported');
        return;
      }

      if (Notification.permission === 'denied') {
        this.render('blocked');
        return;
      }

      const registration = await this.registration();
      if (!current()) return;

      if (!registration) {
        this.render('unsupported');
        return;
      }

      const subscription = await registration.pushManager.getSubscription();
      if (!current()) return;

      const known = this.subscriptionsValue.find((entry) => entry.endpoint === subscription?.endpoint);

      if (known) {
        this.render('enabled', true);
      } else {
        await subscription?.unsubscribe().catch(() => false);
        if (!current()) return;
        this.render('disabled');
      }
    } catch {
      if (current()) this.render('error');
    } finally {
      if (current()) this.setBusy(false);
    }
  }

  async enable():Promise<void> {
    this.generation += 1;
    this.setBusy(true);
    let subscription:PushSubscription|undefined;

    try {
      const registration = await this.registration();
      if (!registration) {
        this.render('unsupported');
        return;
      }

      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: decodeBase64Url(this.vapidPublicKeyValue),
      });
      const response = await post(this.createUrlValue, {
        body: JSON.stringify({ push_endpoint: subscription.endpoint }),
        contentType: 'application/json',
        responseKind: 'turbo-stream',
      });
      if (!response.ok) throw new Error(`Request failed with ${response.statusCode}`);

      this.render('enabled', true);
    } catch {
      await subscription?.unsubscribe().catch(() => false);
      this.render(Notification.permission === 'denied' ? 'blocked' : 'error');
    } finally {
      this.setBusy(false);
    }
  }

  async disable():Promise<void> {
    this.setBusy(true);

    try {
      const registration = await navigator.serviceWorker.getRegistration();
      const subscription = await registration?.pushManager.getSubscription();
      const known = this.subscriptionsValue.find((entry) => entry.endpoint === subscription?.endpoint);

      if (!subscription || !known) {
        this.render('error', true);
        return;
      }

      const response = await destroy(known.revokeUrl, { responseKind: 'turbo-stream' });
      if (!response.ok) throw new Error(`Request failed with ${response.statusCode}`);

      await subscription.unsubscribe().catch(() => false);
      this.render('disabled');
    } catch {
      this.render('error', true);
    } finally {
      this.setBusy(false);
    }
  }

  private async registration():Promise<ServiceWorkerRegistration|undefined> {
    const existing = await navigator.serviceWorker.getRegistration();
    if (existing?.active) return existing;

    let timer:ReturnType<typeof setTimeout>|undefined;
    const timeout = new Promise<undefined>((resolve) => {
      timer = setTimeout(resolve, REGISTRATION_TIMEOUT_MS);
    });

    try {
      return await Promise.race([navigator.serviceWorker.ready, timeout]);
    } finally {
      clearTimeout(timer);
    }
  }

  private supported():boolean {
    return window.isSecureContext
      && 'PushManager' in window
      && 'serviceWorker' in navigator
      && 'Notification' in window;
  }

  private setBusy(busy:boolean):void {
    this.enableTarget.disabled = busy;
    this.disableTarget.disabled = busy;
  }

  private render(state:State, subscribed = false):void {
    this.statusTarget.textContent = I18n.t(STATUS_KEYS[state]);
    const actionable = state !== 'unsupported' && state !== 'blocked';
    this.enableTarget.hidden = !actionable || subscribed;
    this.disableTarget.hidden = !actionable || !subscribed;
  }
}
