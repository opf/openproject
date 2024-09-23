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

export default class extends Controller {
  static values = {
    cancelUrl: String,
  };

  declare cancelUrlValue:string;

  connect():void {
    this.focusInput();
  }

  focusInput():void {
    const titleInput = this.element.querySelector('input[name="meeting_section[title]"]');

    this.element.scrollIntoView({ block: 'center' });
    (titleInput as HTMLInputElement).focus();
    this.setCursorAtEnd(titleInput as HTMLInputElement);
  }

  async cancel() {
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

  setCursorAtEnd(inputElement:HTMLInputElement):void {
    if (document.activeElement === inputElement) {
      const valueLength = inputElement.value.length;
      inputElement.setSelectionRange(valueLength, valueLength);
    }
  }
}
