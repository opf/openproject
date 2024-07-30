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

export default class AsyncDialogController extends ApplicationController {
  private loadingDialog:HTMLDialogElement|null;

  connect() {
    this.element.addEventListener('click', (e) => {
      e.preventDefault();
      this.triggerTurboStream();
    });
  }

  triggerTurboStream():void {
    let loaded = false;

    setTimeout(() => {
      if (!loaded) {
        this.addLoading();
      }
    }, 100);

    fetch(this.href, {
      method: this.method,
      headers: {
        Accept: 'text/vnd.turbo-stream.html',
      },
    }).then((r) => r.text())
      .then((html) => {
        loaded = true;
        renderStreamMessage(html);
      })
      .finally(() => this.removeLoading());
  }

  removeLoading() {
    this.loadingDialog?.remove();
  }

  addLoading() {
    this.removeLoading();
    const dialog = document.createElement('dialog');
    dialog.classList.add('Overlay', 'Overlay--size-medium', 'Overlay--motion-scaleFade');
    dialog.style.height = '150px';
    dialog.style.display = 'grid';
    dialog.style.placeContent = 'center';
    dialog.id = 'loading';
    dialog.innerHTML = `
    <svg style="box-sizing: content-box; color: var(--color-icon-primary);" width="32" height="32" viewBox="0 0 16 16" fill="none" data-view-component="true" class="anim-rotate">
      <circle cx="8" cy="8" r="7" stroke="currentColor" stroke-opacity="0.25" stroke-width="2" vector-effect="non-scaling-stroke" fill="none" />
      <path d="M15 8a7.002 7.002 0 00-7-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" vector-effect="non-scaling-stroke" />
    </svg>
    `;
    document.body.appendChild(dialog);
    dialog.showModal();
    this.loadingDialog = dialog;
  }

  get href() {
    return (this.element as HTMLLinkElement).href;
  }

  get method() {
    return (this.element as HTMLLinkElement).dataset.turboMethod || 'GET';
  }
}
