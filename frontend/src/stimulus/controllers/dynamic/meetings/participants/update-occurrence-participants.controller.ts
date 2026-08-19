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

import { Controller } from '@hotwired/stimulus';

export default class UpdateOccurrenceParticipantsController extends Controller {
  static targets = ['removeButton', 'controlCheckbox'];

  // Tracks checkbox state so it isn't reset after every action
  // Initially true to match the rendered default
  private applyToUpcoming = true;

  controlCheckboxTargetConnected(element:HTMLInputElement):void {
    element.checked = this.applyToUpcoming;
    element.addEventListener('change', this.handleCheckboxChange);
  }

  controlCheckboxTargetDisconnected(element:HTMLInputElement):void {
    element.removeEventListener('change', this.handleCheckboxChange);
  }

  removeButtonTargetConnected(element:HTMLAnchorElement):void {
    element.addEventListener('click', this.handleRemoveClick);
  }

  removeButtonTargetDisconnected(element:HTMLAnchorElement):void {
    element.removeEventListener('click', this.handleRemoveClick);
  }

  private handleCheckboxChange = (event:Event):void => {
    this.applyToUpcoming = (event.target as HTMLInputElement).checked;
  };

  private handleRemoveClick = (event:MouseEvent):void => {
    const button = event.currentTarget as HTMLAnchorElement;
    const url = new URL(button.href);
    if (this.applyToUpcoming) {
      url.searchParams.set('apply_to_upcoming', '1');
    } else {
      url.searchParams.delete('apply_to_upcoming');
    }
    button.href = url.toString();
  };
}
