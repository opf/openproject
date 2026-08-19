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
 *
 */

import { Controller } from '@hotwired/stimulus';

export default class ProjectCustomFieldModalController extends Controller {
  static values = {
    url: { type: String },
  };

  declare urlValue:string;

  open(event:Event) {
    const target = event.target as HTMLElement;

    // Check if the event is on an interactive element that should be ignored
    if (this.isInteractiveElement(target)) {
      // Don't handle this event, let the child element handle it
      return;
    }

    // Prevent default and dispatch custom event for async-dialog to handle
    event.preventDefault();
    this.dispatch('open-dialog', { detail: { url: this.urlValue } });
  }

  private isInteractiveElement(element:HTMLElement):boolean {
    // Check if the element is or is inside an interactive element.
    let current = element;
    while (current && current !== this.element) {
      // Mark dialogs as interactive elements so that they can be ignored.
      // They can be rendered inside the project custom field edit container,
      // as part of the attribute component.
      if (current.matches('button, a, dialog')) {
        return true;
      }
      current = current.parentElement!;
    }
    return false;
  }
}
