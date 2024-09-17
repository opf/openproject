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
import * as URI from 'urijs';

export default class RepositorySettingsController extends Controller {
  static targets = [
    'scmVendor',
    'scmTypeSwitch',
    'scmTypeOptions',
  ];

  declare readonly scmVendorTarget:HTMLSelectElement;

  declare readonly scmTypeOptionsTargets:HTMLFieldSetElement[];

  scmTypeSwitchTargetConnected(el:HTMLFieldSetElement) {
    // Open content if there is only one possible selection
    const checkedInput = el.querySelector<HTMLInputElement>('input[name=scm_type]:checked');
    if (checkedInput) {
      this.selectFieldset(checkedInput.value);
    }
  }

  updateSelectedType(event:InputEvent) {
    const select = event.target as HTMLSelectElement;
    const url = URI(select.dataset.url as string)
      .search({ scm_vendor: select.value });

    window.location.href = url.toString();
  }

  toggleContent(event:InputEvent) {
    this.selectFieldset((event.target as HTMLInputElement).value);
  }

  private selectFieldset(selected:string) {
    const vendor = this.scmVendorTarget.value;
    const targetName = `${vendor}-${selected}`;
    const selectedFieldset = document.getElementById(targetName) as HTMLFieldSetElement;

    this
      .scmTypeOptionsTargets
      .forEach((fieldset:HTMLFieldSetElement) => {
        if (fieldset === selectedFieldset) {
          return;
        }

        fieldset.hidden = fieldset !== selectedFieldset;
        fieldset.disabled = fieldset !== selectedFieldset;

        fieldset
          .querySelectorAll('input,select')
          .forEach((el:HTMLInputElement) => {
            el.disabled = true;
          });
      });

    selectedFieldset.hidden = false;
    selectedFieldset
      .querySelectorAll('input,select')
      .forEach((el:HTMLInputElement) => {
        if (!el.matches('[aria-disabled="true"]')) {
          el.disabled = false;
        }
      });
  }
}
