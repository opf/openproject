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
import { post } from '@rails/request.js';
import { currentPushSubscription, pushSupported } from 'core-stimulus/helpers/push-subscription-helpers';
import { TurboVisitTracker } from 'core-turbo/turbo-visit-tracker';

const ATTEMPTED_STORAGE_KEY = 'push-resume-attempted';
const ATTEMPTED_SESSIONS_LIMIT = 5;
const REQUEST_TIMEOUT_MS = 15000;

/**
 * Re-registers this browser's push subscription with the server after a new
 * sign-in, once per session. A session is remembered once the server gave a
 * definitive answer, such as ok or gone (nothing to resume); a transient
 * failure (network error, timeout, 408, 429 or 5xx) is tried again on the next
 * page load.
 *
 * It does not run on Turbo previews, restored history snapshots or pages
 * served from the back/forward cache, because they can carry a stale CSRF token
 * and a CSRF failure resets the session. The page is checked again right before
 * posting, since a snapshot can replace it while the subscription lookup is
 * pending. The Browser notifications tab handles its own page.
 */
export default class PwaPushResumeController extends Controller {
  static values = {
    url: String,
    session: String,
  };

  private static sessionInFlight:string|undefined;

  declare readonly urlValue:string;
  declare readonly sessionValue:string;

  connect():void {
    if (!this.pageIsFresh()) return;
    if (!this.pushAvailable()) return;
    if (document.querySelector('[data-controller~="my--push-subscription"]')) return;
    if (this.alreadyAttempted() || PwaPushResumeController.sessionInFlight === this.sessionValue) return;

    PwaPushResumeController.sessionInFlight = this.sessionValue;
    void this.resume();
  }

  private async resume():Promise<void> {
    try {
      const subscription = await currentPushSubscription();
      if (!subscription || !this.pageIsFresh()) return;

      const response = await post(this.urlValue, {
        body: JSON.stringify({ push_endpoint: subscription.endpoint, resume: true }),
        contentType: 'application/json',
        responseKind: 'json',
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
      if (this.definitiveAnswer(response.statusCode)) this.markAttempted();
    } catch {
      return;
    } finally {
      PwaPushResumeController.sessionInFlight = undefined;
    }
  }

  private definitiveAnswer(status:number):boolean {
    return status < 500 && status !== 408 && status !== 429;
  }

  private pageIsFresh():boolean {
    return this.element.isConnected
      && !document.documentElement.hasAttribute('data-turbo-preview')
      && TurboVisitTracker.lastAction !== 'restore'
      && !(TurboVisitTracker.lastAction === undefined && this.loadedFromHistory());
  }

  private loadedFromHistory():boolean {
    const [navigation] = performance.getEntriesByType('navigation') as PerformanceNavigationTiming[];
    return navigation?.type === 'back_forward';
  }

  private pushAvailable():boolean {
    return pushSupported() && Notification.permission === 'granted';
  }

  private alreadyAttempted():boolean {
    return this.attemptedSessions().includes(this.sessionValue);
  }

  private markAttempted():void {
    this.storeAttemptedSessions([this.sessionValue, ...this.attemptedSessions()].slice(0, ATTEMPTED_SESSIONS_LIMIT));
  }

  private storeAttemptedSessions(sessions:string[]):void {
    try {
      localStorage.setItem(ATTEMPTED_STORAGE_KEY, JSON.stringify(sessions));
    } catch {
      return;
    }
  }

  private attemptedSessions():string[] {
    try {
      const stored:unknown = JSON.parse(localStorage.getItem(ATTEMPTED_STORAGE_KEY) ?? '[]');
      return Array.isArray(stored) ? stored.filter((entry) => typeof entry === 'string') : [];
    } catch {
      return [];
    }
  }
}
