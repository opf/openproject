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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import { FetchRequest } from '@rails/request.js';
import { TurboHelpers } from 'core-turbo/helpers';

export default class AsyncDialogController extends Controller {
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
    const event = this.dispatch('beforeLoad', { cancelable: true, detail: { form } });
    if (event.defaultPrevented) return;

    const method = form?.method ?? this.method;
    const url = urlOverride ?? form?.action ?? this.href;
    const body = form ? new FormData(form) : undefined;

    this.setLoading(true);
    TurboHelpers.showProgressBar();

    try {
      const response = await new FetchRequest(method, url, {
        body,
        responseKind: 'turbo-stream',
      }).perform();

      if (!response.isTurboStream) {
        throw new Error('Response is not a Turbo Stream');
      }

      // request.js renders successful and 422 streams automatically. Preserve
      // async-dialog's existing any-status stream behavior for every other
      // response until #AGILE-393 defines an application-wide policy.
      if (!response.ok && !response.unprocessableEntity) {
        await response.renderTurboStream();
      }
    } finally {
      this.setLoading(false);
      TurboHelpers.hideProgressBar();
    }
  }

  handleOpenDialog(event:CustomEvent<{ url:string }>):void {
    // Trigger the dialog with custom URL
    void this.triggerTurboStream(event.detail.url);
  }

  get href():string {
    return (this.element as HTMLLinkElement).href;
  }

  get method():string {
    return (this.element as HTMLLinkElement).dataset.turboMethod ?? 'GET';
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
