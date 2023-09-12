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

import * as Turbo from '@hotwired/turbo';
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    cancelUrl: String,
  };

  declare cancelUrlValue:string;

  static targets = ['titleInput', 'descriptionInput', 'descriptionAddButton'];
  declare readonly titleInputTarget:HTMLInputElement;
  declare readonly descriptionInputTarget:HTMLInputElement;
  declare readonly descriptionAddButtonTarget:HTMLInputElement;

  connect():void {
    this.focusInput();
  }

  focusInput():void {
    const titleInput = this.element.querySelector('input[name="meeting_agenda_item[title]"]');
    const wpInput = this.element.querySelector('#op-agenda-items-wp-autocomplete'); // TODO: not working yet -> which element needs to be focused?

    //TODO: using timeout as a quick fix as the author autocomple input takes the focus otherwise
    setTimeout(() => {
      // only one of the two elements will be rendered
      if (titleInput) {
        (titleInput as HTMLInputElement).focus();
      }
      if (wpInput) {
        (wpInput as HTMLInputElement).focus();
      }
    }, 100);
  }

  async cancel() {
    // eslint-disable-next-line no-alert
    const confirmed = window.confirm('Are you sure?');
    if (!confirmed) {
      return;
    }
    const response = await fetch(this.cancelUrlValue, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement).content,
        Accept: 'text/vnd.turbo-stream.html',
      },
    });

    if (response.ok) {
      const text = await response.text();
      Turbo.renderStreamMessage(text);
    }
  }

  async addDescription() {
    this.descriptionInputTarget.classList.remove('d-none');
    this.descriptionAddButtonTarget.classList.add('d-none');
    const textarea = this.element.querySelector('textarea[name="meeting_agenda_item[description]"]');
    setTimeout(() => {
      if (textarea) {
        (textarea as HTMLInputElement).focus();
      }
    }, 100);
  }
}
