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
import {
  IUserAutocompleteItem,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';

export default class UserLimitController extends Controller {
  static targets = [
    'limitWarning',
  ];

  static values = {
    openSeats: Number,
    // Special case, that the autocompleter is a members-autocompleter, instead of the normal user-autocompleter
    memberAutocompleter: Boolean,
  };

  declare readonly limitWarningTarget:HTMLElement;
  declare readonly hasLimitWarningTarget:boolean;

  declare readonly openSeatsValue:number;
  declare readonly hasOpenSeatsValue:boolean;
  declare readonly memberAutocompleterValue:boolean;

  private autocompleterListener = this.triggerLimitWarningIfReached.bind(this);
  private selectedValues:IUserAutocompleteItem[] = [];

  connect() {
    this.autocompleterElement.addEventListener('change', this.autocompleterListener);
  }

  disconnect() {
    this.autocompleterElement.removeEventListener('change', this.autocompleterListener);
  }

  triggerLimitWarningIfReached(evt:CustomEvent) {
    this.selectedValues = evt.detail as IUserAutocompleteItem[];

    if (this.hasLimitWarningTarget && this.hasOpenSeatsValue) {
      if (this.numberOfNewUsers > 0 && this.numberOfNewUsers > this.openSeatsValue) {
        this.limitWarningTarget.classList.remove('d-none');
      } else {
        this.limitWarningTarget.classList.add('d-none');
      }
    }
  }

  // Accessors
  private get autocompleterElement():HTMLElement {
    if (this.memberAutocompleterValue) {
      return this.element.querySelector('opce-members-autocompleter') as HTMLElement;
    }

    return this.element.querySelector('opce-user-autocompleter') as HTMLElement;
  }

  private get numberOfNewUsers() {
    return this.selectedValues.filter(({ id }) => typeof (id) === 'string' && id.includes('@')).length;
  }
}
