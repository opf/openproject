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

// Serialize a form's fields into a query string. URLSearchParams does not accept
// a FormData object whose entries may hold File values, so copy the string
// entries across explicitly, dropping any file inputs.
export function serializeFormQuery(form:HTMLFormElement):string {
  const params = new URLSearchParams();
  new FormData(form).forEach((value, key) => {
    if (typeof value === 'string') {
      params.append(key, value);
    }
  });
  return params.toString();
}

export default class RefreshOnFormChangesController extends ApplicationController {
  static debounces = [
    { name: 'performTurboStreamRefresh', wait: TURBO_STREAM_REFRESH_DELAY },
  ];

  static targets = [
    'form',
  ];

  static values = {
    refreshUrl: String,
    turboStreamUrl: String,
  };

  declare readonly formTarget:HTMLFormElement;

  declare refreshUrlValue:string;
  declare turboStreamUrlValue:string;

  private abortController:AbortController|null = null;

  connect():void {
    useDebounce(this);
  }

  disconnect():void {
    this.abortController?.abort();
    this.abortController = null;
  }

  triggerReload():void {
    window.location.replace(`${this.refreshUrlValue}?${serializeFormQuery(this.formTarget)}`);
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
      const request = new FetchRequest('get', this.turboStreamUrlValue, {
        query: new FormData(this.formTarget),
        responseKind: 'turbo-stream',
        signal: abortController.signal,
      });
      await request.perform();
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
