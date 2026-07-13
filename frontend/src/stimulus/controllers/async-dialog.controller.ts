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

import { ApplicationController } from 'stimulus-use';
import { renderStreamMessage } from '@hotwired/turbo';
import { TurboHelpers } from 'core-turbo/helpers';

export default class AsyncDialogController extends ApplicationController {
  static values = { disableDuringLoad: { type: Boolean, default: true } };

  declare disableDuringLoadValue:boolean;

  private loading = false;

  connect() {
    // Only bind events if we have an href to work with
    if (this.href) {
      this.bindEventListeners();
    }
  }

  private bindEventListeners() {
    this.element.addEventListener('click', (event:MouseEvent) => {
      event.preventDefault();
      this.triggerTurboStream(this.href);
    });

    this.element.addEventListener('keydown', (event:KeyboardEvent) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        this.triggerTurboStream(this.href);
      }
    });
  }

  private triggerTurboStream(url:string):void {
    if (this.disableDuringLoadValue && this.loading) return;

    if (this.disableDuringLoadValue) {
      this.loading = true;
      (this.element as HTMLElement).setAttribute('aria-disabled', 'true');
    }
    TurboHelpers.showProgressBar();

    void fetch(url, {
      method: this.method,
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
      },
    }).then((response) => {
      const contentType = response.headers.get('Content-Type') ?? '';
      const isTurboStream = contentType.includes('text/vnd.turbo-stream.html');

      if (!isTurboStream) {
        return Promise.reject(new Error('Response is not a Turbo Stream'));
      }

      return response.text();
    }).then((html) => {
      renderStreamMessage(html);
    }).finally(() => {
      if (this.disableDuringLoadValue) {
        this.loading = false;
        (this.element as HTMLElement).removeAttribute('aria-disabled');
      }
      TurboHelpers.hideProgressBar();
    });
  }

  handleOpenDialog(event:CustomEvent<{ url:string }>):void {
    // Trigger the dialog with custom URL
    this.triggerTurboStream(event.detail.url);
  }

  get href() {
    return (this.element as HTMLLinkElement).href;
  }

  get method() {
    return (this.element as HTMLLinkElement).dataset.turboMethod ?? 'GET';
  }
}
