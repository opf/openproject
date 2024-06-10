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

export default class AvailableProjectMappingsFilterController extends Controller {
  static targets = [
    'filter',
    'searchItem',
  ];

  declare readonly filterTarget:HTMLInputElement;
  declare readonly searchItemTargets:HTMLInputElement[];

  connect():void {
    this.element.querySelector('#available-project-mappings-filter-clear-button')?.addEventListener('click', () => {
      this.resetFilterViaClearButton();
    });
  }

  disconnect():void {
    this.element.querySelector('#available-project-mappings-filter-clear-button')?.removeEventListener('click', () => {
      this.resetFilterViaClearButton();
    });
  }

  filterLists() {
    const query = this.filterTarget.value.toLowerCase();

    this.searchItemTargets.forEach((item) => {
      const text = item.textContent?.toLowerCase();

      if (text?.includes(query)) {
        (item as HTMLElement).classList.remove('d-none');
      } else {
        (item as HTMLElement).classList.add('d-none');
      }
    });
  }

  resetFilterViaClearButton() {
    this.searchItemTargets.forEach((item) => {
      (item as HTMLElement).classList.remove('d-none');
    });
  }
}
