/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { ApplicationController, useDebounce } from 'stimulus-use';
import { FetchRequest } from '@rails/request.js';

const TURBO_STREAM_REFRESH_DELAY = 50;

/**
 * Posts a form to a Turbo Stream refresh endpoint when configured form fields change.
 *
 * Wire it on the form with `data-controller="refresh-on-form-changes"`,
 * `data-refresh-on-form-changes-target="form"`,
 * `data-refresh-on-form-changes-turbo-stream-url-value="..."`, and trigger it
 * from fields with `change->refresh-on-form-changes#triggerTurboStream`.
 */
export default class RefreshOnFormChangesController extends ApplicationController {
  static debounces = [
    { name: 'performTurboStreamRefresh', wait: TURBO_STREAM_REFRESH_DELAY },
  ];

  static targets = [
    'form',
  ];

  static values = {
    turboStreamUrl: String,
  };

  declare readonly formTarget:HTMLFormElement;

  declare turboStreamUrlValue:string;

  private abortController:AbortController|null = null;

  connect():void {
    useDebounce(this);
  }

  disconnect():void {
    this.abortController?.abort();
    this.abortController = null;
  }

  triggerTurboStream():void {
    void this.performTurboStreamRefresh();
  }

  private async performTurboStreamRefresh():Promise<void> {
    // Cancel any refresh still in flight so a slower, earlier response cannot
    // arrive last and overwrite the form with stale state (e.g. a half-entered
    // date range clobbering the completed one).
    this.abortController?.abort();
    const abortController = new AbortController();
    this.abortController = abortController;

    try {
      // POST the form in the request body so entered data (and the CSRF token)
      // never appears in a URL, address bar, Referer header, or access log.
      // Copy only string entries: the refresh just re-renders the form, so
      // posting selected File blobs would upload them on every keystroke and
      // leak them to an endpoint that never reads them.
      const body = new FormData();
      new FormData(this.formTarget).forEach((value, key) => {
        if (typeof value === 'string') {
          body.append(key, value);
        }
      });
      // Edit forms carry a `_method` field (PUT/PATCH) for their real submit.
      // Rack::MethodOverride would rewrite this POST to that verb before
      // routing, missing the POST-only refresh route, so drop it here.
      body.delete('_method');
      const request = new FetchRequest('post', this.turboStreamUrlValue, {
        body,
        responseKind: 'turbo-stream',
        signal: abortController.signal,
      });
      // perform() resolves (never rejects) on HTTP error statuses and only
      // renders the stream for 2xx/422. Surface anything else so a failed
      // refresh is not swallowed, leaving the form showing stale options.
      const response = await request.perform();
      if (!response.ok && response.statusCode !== 422) {
        console.error(`Form refresh failed (HTTP ${response.statusCode})`);
      }
    } catch (error) {
      if (!(error instanceof DOMException && error.name === 'AbortError')) {
        console.error(error);
      }
    } finally {
      if (this.abortController === abortController) {
        this.abortController = null;
      }
    }
  }
}
