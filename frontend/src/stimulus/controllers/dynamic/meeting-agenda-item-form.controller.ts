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

import * as Turbo from '@hotwired/turbo';
import { Controller } from '@hotwired/stimulus';
import { useMeta } from 'stimulus-use';

export default class extends Controller {
  static values = {
    cancelUrl: String,
    autofocus: Boolean,
  };

  declare cancelUrlValue:string;
  declare autofocusValue:boolean;

  static targets = ['notesInput'];
  declare readonly notesInputTarget:HTMLInputElement;

  static metaNames = ['csrf-token'];
  declare readonly csrfToken:string;

  connect():void {
    useMeta(this, { suffix: false });
    this.focusInput();
    this.addNotes();
    this.storeInitialValues();
  }

  storeInitialValues():void {
    this.element.querySelectorAll('input[type="text"], input[type="number"]').forEach((input) => {
      (input as HTMLInputElement).dataset.initialValue = (input as HTMLInputElement).value;
    });
  }

  focusInput():void {
    const titleInput = this.element.querySelector('input[name="meeting_agenda_item[title]"]');

    if (titleInput && this.autofocusValue) {
      setTimeout(() => {
        (titleInput as HTMLInputElement).focus();
        this.setCursorAtEnd(titleInput as HTMLInputElement);
      }, 25); // Magic number - unsure why, but fixes the issue of focus sometimes not being on the input
    }
  }

  async cancel() {
    const response = await fetch(this.cancelUrlValue, {
      method: 'GET',
      headers: {
        'X-CSRF-Token': this.csrfToken,
        Accept: 'text/vnd.turbo-stream.html',
      },
    });

    if (response.ok) {
      const text = await response.text();
      Turbo.renderStreamMessage(text);
    }
  }

  addNotes() {
    this.notesInputTarget.classList.remove('d-none');
  }

  setCursorAtEnd(inputElement:HTMLInputElement):void {
    if (document.activeElement === inputElement) {
      const valueLength = inputElement.value.length;
      inputElement.setSelectionRange(valueLength, valueLength);
    }
  }
}
