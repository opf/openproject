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
  current?:boolean;
}

type State = 'unsupported'|'blocked'|'enabled'|'disabled'|'error'|'prompting'|'subscribing'|'timeout';

const REGISTRATION_TIMEOUT_MS = 5000;
const SUBSCRIBE_TIMEOUT_MS = 30000;

function decodeBase64Url(value:string):Uint8Array<ArrayBuffer> {
  // The key is base64url without padding; atob only accepts standard base64.
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
}

function assertOk(response:{ ok:boolean; statusCode:number }):void {
  if (!response.ok) throw new Error(`Request failed with ${response.statusCode}`);
}

/**
 * Owns the "this device" box on the Browser push tab of My account.
 *
 * The server is the source of truth, and both directions are reconciled. A
 * browser push subscription only counts when its endpoint is in the list the
 * server rendered into this element and it is bound to the current VAPID key;
 * otherwise it is dropped, because a revoke from another device, a logout or a
 * key rotation has already invalidated it. A server row for this device without
 * a browser subscription (the browser deactivates it when notification
 * permission is revoked) is revoked.
 *
 * Flow
 *
 * - connect: reconcile the browser's subscription with the server list and
 *   render enabled, disabled, blocked (permission denied), unsupported or error.
 * - enable: ensure permission is granted, subscribe through the browser's push
 *   service within a deadline, then register the endpoint with the server. A
 *   failed or late subscription is dropped, so the two sides never disagree.
 * - disable: revoke on the server first, then in the browser.
 *
 * A run counter stops a reconcile that is still in flight from overwriting the
 * result of a later click, or rendering into an element that left the page.
 */
export default class PushSubscriptionController extends Controller {
  static values = {
    vapidPublicKey: String,
    createUrl: String,
    subscriptions: Array,
    messages: Object,
  };

  static targets = ['status', 'enable', 'disable'];

  declare readonly vapidPublicKeyValue:string;
  declare readonly createUrlValue:string;
  declare readonly subscriptionsValue:KnownSubscription[];
  declare readonly messagesValue:Record<State, string>;
  declare readonly statusTarget:HTMLElement;
  declare readonly enableTarget:HTMLButtonElement;
  declare readonly disableTarget:HTMLButtonElement;

  private generation = 0;

  connect():void {
    this.setBusy(true);
    void this.sync();
  }

  async enable():Promise<void> {
    this.startRun();
    const generation = this.generation;
    this.setBusy(true);
    let subscription:PushSubscription|undefined;

    try {
      const permission = await this.requestPermission();
      if (permission !== 'granted') {
        this.render(permission === 'denied' ? 'blocked' : 'disabled');
        return;
      }

      const registration = await this.registration();
      if (!registration) {
        this.render('unsupported');
        return;
      }

      this.render('subscribing');
      subscription = await this.subscribeWithDeadline(registration, () => generation !== this.generation);
      if (!subscription) {
        this.render('timeout');
        return;
      }

      await this.registerWithServer(subscription);
      this.render('enabled', true);
    } catch {
      await this.forget(subscription);
      this.render(this.permissionBlocked() ? 'blocked' : 'error');
    } finally {
      this.setBusy(false);
    }
  }

  async disable():Promise<void> {
    this.setBusy(true);

    try {
      const registration = await navigator.serviceWorker.getRegistration();
      const subscription = await registration?.pushManager.getSubscription();
      const known = this.knownToServer(subscription);
      if (!subscription || !known) {
        this.render('error', true);
        return;
      }

      await this.revokeOnServer(known);
      await this.forget(subscription);
      this.render('disabled');
    } catch {
      this.render('error', true);
    } finally {
      this.setBusy(false);
    }
  }

  private async sync():Promise<void> {
    const isLatestRun = this.startRun();

    try {
      if (!this.supported()) {
        this.render('unsupported');
        return;
      }
      if (this.permissionBlocked()) {
        await this.revokeStaleRow(isLatestRun);
        if (isLatestRun()) this.render('blocked');
        return;
      }

      await this.reconcileWithServer(isLatestRun);
    } catch {
      if (isLatestRun()) this.render('error');
    } finally {
      if (isLatestRun()) this.setBusy(false);
    }
  }

  private async reconcileWithServer(isLatestRun:() => boolean):Promise<void> {
    const registration = await this.registration();
    if (!isLatestRun()) return;
    if (!registration) {
      this.render('unsupported');
      return;
    }

    const subscription = await registration.pushManager.getSubscription();
    if (!isLatestRun()) return;

    if (subscription && this.knownToServer(subscription) && this.boundToCurrentKey(subscription)) {
      this.render('enabled', true);
      return;
    }

    await this.revokeStaleRow(isLatestRun);
    if (!isLatestRun()) return;

    await this.forget(subscription);
    if (isLatestRun()) this.render('disabled');
  }

  private async revokeStaleRow(isLatestRun:() => boolean):Promise<void> {
    const staleRow = this.subscriptionsValue.find((entry) => entry.current);
    if (!staleRow || !isLatestRun()) return;

    await this.revokeOnServer(staleRow, { silent: true }).catch(() => undefined);
  }

  private startRun():() => boolean {
    this.generation += 1;
    const generation = this.generation;
    return () => generation === this.generation && this.element.isConnected;
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

  private async requestPermission():Promise<NotificationPermission> {
    if (Notification.permission !== 'default') return Notification.permission;

    const pending = Notification.requestPermission();
    this.render('prompting');

    return (await pending) ?? Notification.permission;
  }

  private async subscribeWithDeadline(
    registration:ServiceWorkerRegistration,
    superseded:() => boolean,
  ):Promise<PushSubscription|undefined> {
    const pending = this.subscribeInBrowser(registration);
    let timer:ReturnType<typeof setTimeout>|undefined;
    const deadline = new Promise<undefined>((resolve) => {
      timer = setTimeout(resolve, SUBSCRIBE_TIMEOUT_MS);
    });

    try {
      const subscription = await Promise.race([pending, deadline]);
      // A newer run may have claimed the same subscription; only an unclaimed late one is dropped.
      if (!subscription) void pending.then((late) => (superseded() ? undefined : this.forget(late)), () => undefined);
      return subscription;
    } finally {
      clearTimeout(timer);
    }
  }

  private subscribeInBrowser(registration:ServiceWorkerRegistration):Promise<PushSubscription> {
    return registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: decodeBase64Url(this.vapidPublicKeyValue),
    });
  }

  private async registerWithServer(subscription:PushSubscription):Promise<void> {
    const response = await post(this.createUrlValue, {
      body: JSON.stringify({ push_endpoint: subscription.endpoint }),
      contentType: 'application/json',
      responseKind: 'turbo-stream',
    });
    assertOk(response);
  }

  private async revokeOnServer(known:KnownSubscription, { silent = false } = {}):Promise<void> {
    const query = silent ? { silent: 'true' } : undefined;
    assertOk(await destroy(known.revokeUrl, { responseKind: 'turbo-stream', query }));
  }

  private async forget(subscription:PushSubscription|null|undefined):Promise<void> {
    await subscription?.unsubscribe().catch(() => false);
  }

  private knownToServer(subscription:PushSubscription|null|undefined):KnownSubscription|undefined {
    return this.subscriptionsValue.find((entry) => entry.endpoint === subscription?.endpoint);
  }

  private boundToCurrentKey(subscription:PushSubscription):boolean {
    const bound = subscription.options.applicationServerKey;
    if (!bound) return true;

    const current = decodeBase64Url(this.vapidPublicKeyValue);
    const boundBytes = new Uint8Array(bound);
    return boundBytes.length === current.length && boundBytes.every((byte, index) => byte === current[index]);
  }

  private permissionBlocked():boolean {
    return Notification.permission === 'denied';
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
    this.statusTarget.textContent = this.messagesValue[state];
    const actionable = state !== 'unsupported' && state !== 'blocked';
    this.enableTarget.hidden = !actionable || subscribed;
    this.disableTarget.hidden = !actionable || !subscribed;
  }
}
