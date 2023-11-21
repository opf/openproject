/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import { Controller } from '@hotwired/stimulus';
import { renderStreamMessage } from '@hotwired/turbo';

export default class OpenProjectStorageModalController extends Controller {
  static values = {
    projectStorageOpenUrl: String,
    redirectUrl: String,
  };

  connect() {
    this.element.open = true;
    this.interval = 0;
    this.load();
    // the following is not enough, because the modal can be closed with Esc when close button in focus
    const closeButton = this.element.getElementsByClassName("Overlay-closeButton")[0]
    closeButton.addEventListener('click', () => { this.disconnect() });
  }

  disconnect() {
    clearInterval(this.interval);
  }

  load() {
    this.interval = setTimeout(
      async () => {
        let response = await fetch(
          this.projectStorageOpenUrlValue,
          {
            headers: {
              'Accept': 'text/vnd.turbo-stream.html'
            }
          }
        )
        if (response.status === 200) {
          let streamActionHTML = await response.text();
          renderStreamMessage(streamActionHTML);
          setTimeout(
            () => { window.location.href = this.redirectUrlValue; },
            2000
          );
        } else {
          this.load();
        }
      },
      3000)
  }
}
