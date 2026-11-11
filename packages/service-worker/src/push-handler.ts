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

import { Badge } from './badge';
import { Config } from './config';
import { SIGN_OUT_TIMEOUT_MS } from './constants';
import { NotificationFingerprint } from './notification-fingerprint';
import { NotificationRules, type SummaryGroup, type SummaryMore } from './notification-rules';
import { Notifications } from './notifications';
import { PushState } from './push-state';
import { sw } from './sw-global';
import { UnreadSummary } from './unread-summary';

/**
 * Turns push wake-ups into notifications and clears them on sign-out.
 *
 * Pushes run one at a time through a queue. Whatever goes wrong, a push ends in a visible
 * notification; for a push that shows nothing Chrome shows a generic notice and Safari may
 * revoke the subscription.
 *
 * ```
 * push event ──► queue ──► GET notification summary
 *                            │
 *                            ├─ signed out (401)
 *                            │               clear badge, close and forget all, fallback
 *                            ├─ unavailable .. fallback
 *                            ├─ empty ........ close and forget all, "all read", clear badge
 *                            └─ unread ....... set badge
 *                                              close notifications no longer listed
 *                                              fingerprint groups ► decide ► show each item
 *                                              save state
 *
 * any error on the way ► fallback
 *
 * logout navigation ──► bump sign-out generation, sign-out in progress
 *                         ├─ clear now
 *                         └─ response settled, or 10 s passed ► bump generation again, clear once
 *                                               more behind any push (it may have re-shown some)
 * summary fetched across a sign-out, or while one is in progress ► discarded, fallback
 *
 * reconcile message ──► queue ──► none of its notifications open? refresh the badge only
 *                                  else GET notification summary, same outcomes as a push except that
 *                                  nothing is shown and "all read" is not announced; unavailable
 *                                  does nothing; unread closes unlisted notifications (marked
 *                                  evicted when more are collapsed), sets the badge, saves state
 *
 * account message ──► user differs from the last one this worker instance saw?
 *                       yes: bump sign-out generation; close and forget every notification
 *                            that is not this user's, including "more" and the placeholder;
 *                            set the badge from this user's summary
 *                       no (or first message since the worker started): close and forget only
 *                            work package notifications of other users
 *                       either way, if anything was closed or forgotten: refresh the badge
 * ```
 */
export class PushHandler {
  private queue:Promise<void> = Promise.resolve();
  private signOutGeneration = 0;
  private signOutsInProgress = 0;
  private accountId:string|undefined;
  private readonly signOutPath:string;

  constructor() {
    this.signOutPath = new URL(Config.urls.signOut, sw.location.href).pathname;
  }

  isSignOut(request:Request):boolean {
    return new URL(request.url).pathname === this.signOutPath;
  }

  static async settled(navigation:Promise<unknown>):Promise<void> {
    let timer:ReturnType<typeof setTimeout>|undefined;
    try {
      await Promise.race([
        navigation.catch(() => undefined),
        new Promise((resolve) => {
          timer = setTimeout(resolve, SIGN_OUT_TIMEOUT_MS);
        }),
      ]);
    } finally {
      clearTimeout(timer);
    }
  }

  signOut(navigation:Promise<unknown>):Promise<unknown> {
    this.signOutGeneration += 1;
    this.signOutsInProgress += 1;
    const cleared = this.clearForSignOut().catch(() => undefined);
    const clearedAfterSettled = PushHandler.settled(navigation).then(() => {
      this.signOutGeneration += 1;
      this.signOutsInProgress -= 1;
      return this.enqueue(() => this.clearForSignOut());
    });
    return Promise.all([cleared, clearedAfterSettled]);
  }

  onPush(event:ExtendableEvent):void {
    event.waitUntil(this.enqueue(() => this.showUnread()));
  }

  onMessage(event:ExtendableMessageEvent):void {
    const { type, userId } = (event.data ?? {}) as { type?:string; userId?:string|number };
    if (type === 'reconcile') {
      event.waitUntil(this.enqueue(() => this.reconcile()));
    } else if (type === 'account' && userId) {
      event.waitUntil(this.switchAccount(String(userId)));
    }
  }

  switchAccount(userId:string):Promise<void> {
    const changed = this.accountId !== undefined && this.accountId !== userId;
    if (changed) this.signOutGeneration += 1;
    this.accountId = userId;
    return this.enqueue(async () => {
      const closed = await this.closeOtherAccounts(userId, changed);
      if (changed || closed) await this.refreshBadge();
    });
  }

  enqueue(task:() => Promise<void>):Promise<void> {
    this.queue = this.queue.then(task, task).catch(() => undefined);
    return this.queue;
  }

  async showUnread():Promise<void> {
    try {
      await this.render();
    } catch {
      await Notifications.showFallback();
    }
  }

  async render():Promise<void> {
    const generation = this.signOutGeneration;
    const summary = await UnreadSummary.fetch();
    if (generation !== this.signOutGeneration || this.signOutsInProgress > 0) return Notifications.showFallback();

    switch (summary.outcome) {
      case 'signedOut':
        await Badge.clear();
        await this.closeAndForgetAll();
        return Notifications.showFallback();
      case 'unavailable':
        return Notifications.showFallback();
      case 'empty':
        await this.closeAndForgetAll();
        await Notifications.showAllRead();
        return Badge.clear();
      default:
        await Badge.set(summary.count);
        return this.showUnreadGroups(summary);
    }
  }

  async reconcile():Promise<void> {
    const generation = this.signOutGeneration;
    if ((await Notifications.listOpen()).length === 0) return this.refreshBadge();

    const summary = await UnreadSummary.fetch();
    if (generation !== this.signOutGeneration || this.signOutsInProgress > 0) return;

    switch (summary.outcome) {
      case 'signedOut':
      case 'empty':
        await this.closeAndForgetAll();
        return Badge.clear();
      case 'unavailable':
        return;
      default:
        await Badge.set(summary.count);
        return this.closeUnlisted(summary);
    }
  }

  async refreshBadge():Promise<void> {
    const generation = this.signOutGeneration;
    const summary = await UnreadSummary.fetch();
    if (generation !== this.signOutGeneration || this.signOutsInProgress > 0) return;
    if (summary.outcome === 'unavailable') return;

    return summary.outcome === 'unread' ? Badge.set(summary.count) : Badge.clear();
  }

  async closeStale({ groups, more }:{ groups:SummaryGroup[]; more?:SummaryMore }) {
    const state = await PushState.read();
    const open = await Notifications.listOpen();
    const openTags = open.map((notification) => notification.tag);
    const closeTags = NotificationRules.staleTags({ groups, more, openTags });
    Notifications.close(open, closeTags);
    return { state, openTags, closeTags };
  }

  async closeUnlisted(summary:{ groups:SummaryGroup[]; more?:SummaryMore }):Promise<void> {
    const { state, closeTags } = await this.closeStale(summary);
    if (closeTags.length === 0) return;

    await PushState.write(NotificationRules.stateAfterClose({ closeTags, more: summary.more, state }));
  }

  async showUnreadGroups(summary:{ groups:SummaryGroup[]; more?:SummaryMore }):Promise<void> {
    const { groups, more } = summary;
    const { state, openTags } = await this.closeStale(summary);
    if (groups.length === 0) return Notifications.showFallback();

    const decision = NotificationRules.decide({ ...(await NotificationFingerprint.addTo({ groups, more })), openTags, state });
    for (const item of decision.show) await Notifications.show(item);
    await PushState.write(decision.state);
  }

  async closeAndForgetAll():Promise<void> {
    Notifications.closeAll(await Notifications.listOpen());
    await PushState.clear();
  }

  async closeOtherAccounts(userId:string, changed:boolean):Promise<boolean> {
    const isOther = (tag:string) => {
      const owner = Notifications.ownerOf(tag);
      return owner === undefined ? changed : owner !== userId;
    };
    const open = await Notifications.listOpen();
    const closeTags = open.map((notification) => notification.tag).filter(isOther);
    Notifications.close(open, closeTags);

    const state = await PushState.read();
    const remembered = Object.entries(state).filter(([tag]) => !isOther(tag));
    const forgot = remembered.length !== Object.keys(state).length;
    if (forgot) await PushState.write(Object.fromEntries(remembered));
    return closeTags.length > 0 || forgot;
  }

  async clearForSignOut():Promise<void> {
    await this.closeAndForgetAll();
    await Badge.clear();
  }
}
