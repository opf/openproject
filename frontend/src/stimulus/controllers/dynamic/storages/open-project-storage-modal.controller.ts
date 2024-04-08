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

export default class OpenProjectStorageModalController extends Controller<HTMLDialogElement> {
  static values = {
    projectStorageOpenUrl: String,
    redirectUrl: String,
  };

  interval:number;
  networkErrorHappend:boolean;
  projectStorageOpenUrlValue:string;
  redirectUrlValue:string;

  connect() {
    this.element.showModal();
    this.interval = 0;
    this.networkErrorHappend = false;
    this.load();
    this.element.addEventListener('close', () => { this.disconnect(); });
    this.element.addEventListener('cancel', () => { this.disconnect(); });
  }

  disconnect() {
    clearInterval(this.interval);
  }

  load() {
    this.interval = setTimeout(
      async () => {
        try {
          const response = await fetch(
            this.projectStorageOpenUrlValue,
            {
              headers: {
                Accept: 'text/vnd.turbo-stream.html',
              },
            },
          );
          if (response.status === 200) {
            const streamActionHTML = await response.text();
            renderStreamMessage(streamActionHTML);
            setTimeout(
              () => { window.location.href = this.redirectUrlValue; },
              2000,
            );
          } else {
            if (this.networkErrorHappend === true) {
              this.setNetworkErrorHappend(false);
            }
            this.load();
          }
        } catch (error:any) {
          console.error('Error: ', error);
          if (this.networkErrorHappend === false) {
            this.setNetworkErrorHappend(true);
          }
          setTimeout(() => this.load(), 3000);
        }
      },
      3000,
    );
  }

  private setNetworkErrorHappend(value:boolean) {
    const waitingSubtitle = document.getElementById('waiting_subtitle');
    if (waitingSubtitle) {
      waitingSubtitle.innerText = I18n.t(
        `js.open_project_storage_modal.waiting_subtitle.network_${value ? 'off' : 'on'}`,
      );
    }
    this.networkErrorHappend = value;
  }
}
