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
import { FetchRequest } from '@rails/request.js';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { performTurboStreamRequest, withProgressBar } from 'core-stimulus/helpers/request-helpers';
import { showErrorToast } from 'core-stimulus/helpers/toast-helpers';

export default class AsyncDialogController extends Controller<HTMLElement> {
  static values = { disableDuringLoad: { type: Boolean, default: true } };

  declare disableDuringLoadValue:boolean;

  private loading = false;

  private readonly handleClick = (event:Event):void => {
    event.preventDefault();
    void this.triggerTurboStream();
  };

  private readonly handleKeydown = (event:Event):void => {
    const keyboardEvent = event as KeyboardEvent;
    if (keyboardEvent.key === 'Enter' || keyboardEvent.key === ' ') {
      event.preventDefault();
      void this.triggerTurboStream();
    }
  };

  connect():void {
    if (this.href || (this.element instanceof HTMLButtonElement && this.element.form)) {
      this.element.addEventListener('click', this.handleClick);
      this.element.addEventListener('keydown', this.handleKeydown);
    }
  }

  disconnect():void {
    this.element.removeEventListener('click', this.handleClick);
    this.element.removeEventListener('keydown', this.handleKeydown);
  }

  private async triggerTurboStream(urlOverride?:string):Promise<void> {
    if (this.disableDuringLoadValue && this.loading) return;

    const form = urlOverride
      ? null
      : this.element instanceof HTMLButtonElement ? this.element.form : null;
    if (!this.resolveUrl(form, urlOverride)) return;

    const event = this.dispatch('beforeLoad', { cancelable: true, detail: { form } });
    if (event.defaultPrevented) return;

    const url = this.resolveUrl(form, urlOverride);
    if (!url) return;

    const method = form?.method ?? this.method;
    const body = form ? new FormData(form) : undefined;

    this.setLoading(true);

    try {
      await withProgressBar(performTurboStreamRequest(new FetchRequest(method, url, {
        body,
        responseKind: 'turbo-stream',
      })));
    } catch (error) {
      // A rejection streams its own flash; only a request that never
      // produced a stream lands here.
      debugLog('Failed to load async dialog', error);
      showErrorToast();
    } finally {
      this.setLoading(false);
    }
  }

  handleOpenDialog(event:CustomEvent<{ url:string }>):void {
    // Trigger the dialog with custom URL
    void this.triggerTurboStream(event.detail.url);
  }

  get href():string|undefined {
    return this.element instanceof HTMLAnchorElement ? this.element.href : undefined;
  }

  get method():string {
    return this.element.dataset.turboMethod ?? 'GET';
  }

  private resolveUrl(form:HTMLFormElement|null, urlOverride?:string):string|undefined {
    return urlOverride ?? form?.action ?? this.href;
  }

  private setLoading(loading:boolean):void {
    this.loading = loading;

    if (this.disableDuringLoadValue) {
      if (loading) {
        this.element.setAttribute('aria-disabled', 'true');
      } else {
        this.element.removeAttribute('aria-disabled');
      }
    }
  }
}
