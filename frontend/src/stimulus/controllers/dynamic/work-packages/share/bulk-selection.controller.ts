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

export default class BulkSelectionController extends Controller {
  static targets = [
    'toggleAll',
    'sharedCounter',
    'selectedCounter',
    'shareCheckbox',
    'hiddenShareIdsContainer',
  ];

  declare readonly toggleAllTarget:HTMLInputElement;
  declare readonly sharedCounterTarget:HTMLElement;
  declare readonly selectedCounterTarget:HTMLElement;
  declare readonly shareCheckboxTargets:HTMLInputElement[];
  declare readonly hiddenShareIdsContainerTargets:HTMLElement[];

  toggleAllTargetConnected() {
    this.refresh();
  }

  shareCheckboxTargetConnected() {
    this.refresh();
  }

  shareCheckboxTargetDisconnected() {
    this.refresh();
  }

  toggle(e:Event) {
    e.preventDefault();

    this.shareCheckboxTargets.forEach((share) => {
      share.checked = this.toggleAllTarget.checked;
    });

    this.shareCheckboxTargets.forEach((share) => {
      this.triggerInputEvent((share));
    });

    this.updateCounter();
  }

  triggerInputEvent(checkbox:HTMLInputElement) {
    const event = new Event('input', { bubbles: false, cancelable: true });
    checkbox.dispatchEvent(event);
  }

  refresh() {
    const checkedSharesCount = this.checked.length;
    const sharesCount = this.shareCheckboxTargets.length;

    this.toggleAllTarget.checked = checkedSharesCount === sharesCount;
    this.updateCounter();
  }

  updateCounter() {
    if (this.checked.length === 0) {
      this.sharedCounterTarget.removeAttribute('hidden');
      this.selectedCounterTarget.setAttribute('hidden', 'true');
    } else {
      this.sharedCounterTarget.setAttribute('hidden', 'true');
      this.selectedCounterTarget.removeAttribute('hidden');
      this.selectedCounterTarget.textContent = I18n.t('js.work_packages.sharing.selected_count', { count: this.checked.length });
    }

    this.hiddenShareIdsContainerTargets.forEach((checkboxIdsContainer) => {
      checkboxIdsContainer.innerHTML = '';
      const hiddenShareIds = this.createHiddenShareIds();
      hiddenShareIds.forEach((hiddenShare) => checkboxIdsContainer.appendChild(hiddenShare));
    });
  }

  createHiddenShareIds() {
    return this.checked.map((checkbox) => {
      const hiddenInput = document.createElement('input');
      hiddenInput.type = 'hidden';
      hiddenInput.name = 'share_ids[]';
      hiddenInput.value = checkbox.value;
      return hiddenInput;
    });
  }

  get checked() {
    return this.shareCheckboxTargets.filter((checkbox) => checkbox.checked);
  }

  get unchecked() {
    return this.shareCheckboxTargets.filter((checkbox) => !checkbox.checked);
  }
}
