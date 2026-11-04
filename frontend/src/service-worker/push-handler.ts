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
import { Digest } from './digest';
import { NotificationPlan, type SummaryGroup, type SummaryMore } from './notification-plan';
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
 * push event ──► queue ──► GET push summary
 *                            │
 *                            ├─ signed out ... clear badge, close and forget all, fallback
 *                            ├─ unavailable .. fallback
 *                            ├─ empty ........ close and forget all, "all read", clear badge
 *                            └─ unread ....... set badge
 *                                              close notifications no longer listed
 *                                              digest groups ► plan ► show each item
 *                                              save state
 *
 * any error on the way ► fallback
 *
 * logout navigation ──► bump sign-out generation
 *                         ├─ clear now
 *                         └─ push queued or running? clear again after it (it may have re-shown some)
 * summary fetched across a sign-out ► discarded, fallback
 * ```
 */
export class PushHandler {
  private queue:Promise<void> = Promise.resolve();
  private pending = 0;
  private signOutGeneration = 0;
  private readonly signOutPath:string;

  constructor() {
    this.signOutPath = new URL(Config.urls.signOut, sw.location.href).pathname;
  }

  isSignOut(request:Request):boolean {
    return new URL(request.url).pathname === this.signOutPath;
  }

  signOut():Promise<unknown> {
    this.signOutGeneration += 1;
    const cleared = this.clearForSignOut().catch(() => undefined);
    const clearedAfterPush = this.pending > 0 ? this.enqueue(() => this.clearForSignOut()) : undefined;
    return Promise.all([cleared, clearedAfterPush]);
  }

  onPush(event:ExtendableEvent):void {
    event.waitUntil(this.enqueue(() => this.showUnread()));
  }

  enqueue(task:() => Promise<void>):Promise<void> {
    this.pending += 1;
    const run = async () => {
      try {
        await task();
      } finally {
        this.pending -= 1;
      }
    };
    this.queue = this.queue.then(run, run).catch(() => undefined);
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
    if (generation !== this.signOutGeneration) return Notifications.showFallback();

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

  async showUnreadGroups({ groups, more }:{ groups:SummaryGroup[]; more?:SummaryMore }):Promise<void> {
    const state = await PushState.read();
    const open = await Notifications.listOpen();
    const openTags = open.map((notification) => notification.tag);
    Notifications.close(open, NotificationPlan.staleTags({ groups, more, openTags }));
    if (groups.length === 0) return Notifications.showFallback();

    const plan = NotificationPlan.for({ ...(await Digest.addTo({ groups, more })), openTags, state });
    for (const item of plan.show) await Notifications.show(item);
    await PushState.write(plan.state);
  }

  async closeAndForgetAll():Promise<void> {
    Notifications.closeAll(await Notifications.listOpen());
    await PushState.clear();
  }

  async clearForSignOut():Promise<void> {
    await this.closeAndForgetAll();
    await Badge.clear();
  }
}
