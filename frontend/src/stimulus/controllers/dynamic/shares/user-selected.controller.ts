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

export default class UserSelectedController extends Controller {
  static targets = [
    'shareButton',
    'error',
  ];

  declare readonly errorTarget:HTMLElement;

  private selectedValues:IUserAutocompleteItem[] = [];

  connect() {
    this.autocompleterElement.addEventListener('change', this.handleValueSelected.bind(this));
  }

  disconnect() {
    this.autocompleterElement.removeEventListener('change', this.handleValueSelected.bind(this));
  }

  ensureUsersSelected(evt:CustomEvent):void {
    if (this.selectedValues.length === 0) {
      evt.preventDefault(); // Don't submit
      this.showError();
    } else {
      this.hideError();
    }
  }

  // Private methods
  handleValueSelected(evt:CustomEvent) {
    this.selectedValues = evt.detail as IUserAutocompleteItem[];

    if (this.selectedValues.length !== 0) {
      this.hideError();
    }
  }

  private showError() {
    this.errorTarget.classList.remove('d-none');
  }

  private hideError() {
    this.errorTarget.classList.add('d-none');
  }

  // Accessors
  private get autocompleterElement():HTMLElement {
    return this.element.querySelector('opce-user-autocompleter') as HTMLElement;
  }
}
