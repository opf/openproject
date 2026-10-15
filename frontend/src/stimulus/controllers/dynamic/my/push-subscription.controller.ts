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
import { boundToKey, decodeBase64Url } from 'core-stimulus/helpers/push-subscription-helpers';

interface KnownSubscription {
  endpoint:string;
  revokeUrl:string;
  current?:boolean;
  dormant?:boolean;
}

type State = 'unsupported'|'blocked'|'enabled'|'disabled'|'error'|'prompting'|'subscribing'|'timeout';

type Attempt = 'enable'|'disable'|'sync';

type Scheme = 'default'|'warning'|'success'|'danger';

const SCHEME_BY_STATE:Record<State, Scheme> = {
  unsupported: 'default',
  blocked: 'warning',
  disabled: 'warning',
  prompting: 'warning',
  subscribing: 'warning',
  enabled: 'success',
  error: 'danger',
  timeout: 'danger',
};

const REGISTRATION_TIMEOUT_MS = 5000;
const SUBSCRIBE_TIMEOUT_MS = 30000;

function assertOk(response:{ ok:boolean; statusCode:number }):void {
  if (!response.ok) throw new Error(`Request failed with ${response.statusCode}`);
}

/**
 * Owns the status banner on the Browser notifications tab of My account.
 *
 * The server is the source of truth, and both directions are reconciled. A
 * browser push subscription only counts when its endpoint is in the list the
 * server rendered into this element and it is bound to the current VAPID key;
 * otherwise it is dropped, because a revoke from another device, a logout or a
 * key rotation has already invalidated it. A server row for this device without
 * a browser subscription (the browser deactivates it when notification
 * permission is revoked) is revoked. A row that lost its session but matches
 * this browser's subscription is resumed by registering it again.
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

  static targets = ['banner', 'message', 'action', 'liveRegion'];

  declare readonly vapidPublicKeyValue:string;
  declare readonly createUrlValue:string;
  declare readonly subscriptionsValue:KnownSubscription[];
  declare readonly messagesValue:Record<State, string>;
  declare readonly bannerTargets:HTMLElement[];
  declare readonly messageTargets:HTMLElement[];
  declare readonly actionTargets:HTMLButtonElement[];
  declare readonly liveRegionTarget:HTMLElement;

  private generation = 0;
  private lastAttempt:Attempt = 'sync';

  connect():void {
    this.setBusy(true);
    void this.sync();
  }

  disconnect():void {
    this.generation += 1;
  }

  retry():Promise<void> {
    this.liveRegionTarget.textContent = '';

    switch (this.lastAttempt) {
      case 'enable':
        return this.enable();
      case 'disable':
        return this.disable();
      default:
        this.setBusy(true);
        return this.sync();
    }
  }

  async enable():Promise<void> {
    this.lastAttempt = 'enable';
    const isLatestRun = this.startRun();
    const generation = this.generation;
    this.setBusy(true);
    let subscription:PushSubscription|undefined;

    try {
      const permission = await this.requestPermission();
      if (permission !== 'granted') {
        if (isLatestRun()) this.render(permission === 'denied' ? 'blocked' : 'disabled');
        return;
      }

      const registration = await this.registration();
      if (!registration) {
        if (isLatestRun()) this.render('unsupported');
        return;
      }

      if (isLatestRun()) this.render('subscribing');
      subscription = await this.subscribeWithDeadline(registration, () => generation !== this.generation);
      if (!subscription) {
        if (isLatestRun()) this.render('timeout');
        return;
      }

      await this.registerWithServer(subscription);
      if (isLatestRun()) this.render('enabled');
    } catch {
      await this.forget(subscription);
      if (isLatestRun()) this.render(this.permissionBlocked() ? 'blocked' : 'error');
    } finally {
      if (isLatestRun()) this.setBusy(false);
    }
  }

  async disable():Promise<void> {
    this.lastAttempt = 'disable';
    const isLatestRun = this.startRun();
    this.setBusy(true);

    try {
      const registration = await navigator.serviceWorker.getRegistration();
      const subscription = await registration?.pushManager.getSubscription();
      if (!isLatestRun()) return;

      const known = this.knownToServer(subscription);
      if (!subscription || !known) {
        this.lastAttempt = 'sync';
        this.render('error');
        return;
      }

      await this.revokeOnServer(known);
      await this.forget(subscription);
      if (isLatestRun()) this.render('disabled');
    } catch {
      if (isLatestRun()) this.render('error');
    } finally {
      if (isLatestRun()) this.setBusy(false);
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

    const known = this.knownToServer(subscription);
    if (subscription && known && this.boundToCurrentKey(subscription)) {
      if (known.dormant) {
        await this.registerWithServer(subscription);
        if (!isLatestRun()) return;
      }

      this.render('enabled');
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
    return boundToKey(subscription, this.vapidPublicKeyValue);
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
    this.actionTargets.forEach((action) => { action.disabled = busy; });
  }

  private render(state:State):void {
    if (!this.element.isConnected) return;

    const scheme = SCHEME_BY_STATE[state];
    const message = this.messagesValue[state];

    this.bannerTargets.forEach((banner) => { banner.hidden = banner.dataset.scheme !== scheme; });
    this.messageTargets.forEach((target) => {
      target.textContent = target.dataset.scheme === scheme ? message : '';
    });
    this.liveRegionTarget.textContent = message;
    this.actionTargets.forEach((action) => {
      if (action.dataset.scheme === 'warning') action.hidden = state === 'blocked';
    });
  }
}
