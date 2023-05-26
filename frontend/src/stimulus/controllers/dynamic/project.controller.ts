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
 *
 */

import { Controller } from '@hotwired/stimulus';

export default class ProjectController extends Controller {
  connect() {
    // console.log('Project Controller Connected');
  }

  toggleMultiSelect(event:Event) {
    const valueSelector = (event.target as HTMLElement).closest('.advanced-filters--filter-value') as HTMLElement;
    const singleSelect = valueSelector.querySelector('.single-select select') as HTMLSelectElement;
    const multiSelect = valueSelector.querySelector('.multi-select select') as HTMLSelectElement;

    if (valueSelector.classList.contains('multi-value')) {
      const valueToSelect = this.getValueToSelect(multiSelect);
      this.setSelectOptions(singleSelect, valueToSelect);
    } else {
      const valueToSelect = this.getValueToSelect(singleSelect);
      this.setSelectOptions(multiSelect, valueToSelect);
    }

    valueSelector.classList.toggle('multi-value');
  }

  private getValueToSelect(selectElement:HTMLSelectElement) {
    return selectElement.selectedOptions[0]?.value;
  }

  private setSelectOptions(selectElement:HTMLSelectElement, selectedValue:string) {
    Array.from(selectElement.options).forEach((option) => {
      option.selected = option.value === selectedValue;
    });
  }
}
