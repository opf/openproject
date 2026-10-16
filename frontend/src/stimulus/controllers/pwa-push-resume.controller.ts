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
import { currentPushSubscription } from 'core-stimulus/helpers/push-subscription-helpers';

const ATTEMPTED_STORAGE_KEY = 'push-resume-attempted';
const ATTEMPTED_SESSIONS_LIMIT = 5;
const RENDERED_AT_MAX_AGE_MS = 120000;

/**
 * Re-registers this browser's push subscription with the server after a new
 * sign-in, once per session. A failed attempt is forgotten so the next page
 * load tries again.
 *
 * It does not run on Turbo previews or on pages rendered more than two minutes
 * ago, because a restored snapshot can carry a stale CSRF token and a CSRF
 * failure resets the session. The Browser push tab handles its own page.
 */
export default class PwaPushResumeController extends Controller {
  static values = {
    url: String,
    session: String,
  };

  declare readonly urlValue:string;
  declare readonly sessionValue:string;

  connect():void {
    if (document.documentElement.hasAttribute('data-turbo-preview')) return;
    if (!this.pushAvailable()) return;
    if (document.querySelector('[data-controller~="my--push-subscription"]')) return;
    if (this.alreadyAttempted() || this.renderedTooLongAgo()) return;

    this.markAttempted();
    void this.resume();
  }

  private async resume():Promise<void> {
    try {
      const subscription = await currentPushSubscription();
      if (!subscription) return;

      const response = await post(this.urlValue, {
        body: JSON.stringify({ push_endpoint: subscription.endpoint, resume: true }),
        contentType: 'application/json',
        responseKind: 'turbo-stream',
      });
      if (!response.ok) this.unmarkAttempted();
    } catch {
      this.unmarkAttempted();
    }
  }

  private pushAvailable():boolean {
    return window.isSecureContext
      && 'PushManager' in window
      && 'serviceWorker' in navigator
      && 'Notification' in window
      && Notification.permission === 'granted';
  }

  private alreadyAttempted():boolean {
    return this.attemptedSessions().includes(this.sessionValue);
  }

  private markAttempted():void {
    this.storeAttemptedSessions([this.sessionValue, ...this.attemptedSessions()].slice(0, ATTEMPTED_SESSIONS_LIMIT));
  }

  private unmarkAttempted():void {
    this.storeAttemptedSessions(this.attemptedSessions().filter((entry) => entry !== this.sessionValue));
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

  private renderedTooLongAgo():boolean {
    const renderedAt = Date.parse(document.body.dataset.renderedAt ?? '');
    return Number.isNaN(renderedAt) || Date.now() - renderedAt > RENDERED_AT_MAX_AGE_MS;
  }
}
