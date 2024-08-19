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

export default class BulkSelectionController extends Controller {
  static values = {
    bulkUpdateRoleLabel: { type: String, default: I18n.t('js.sharing.selection.mixed') },
  };

  declare bulkUpdateRoleLabelValue:string;

  static targets = [
    'toggleAll',
    'shareCheckbox',
    'sharedCounter',
    'selectedCounter',
    'defaultActions',
    'bulkActions',
    'bulkForm',
    'hiddenShare',
    'userRowRole',
    'bulkUpdateRoleLabel',
    'bulkUpdateRoleForm',
  ];

  // Checkboxes
  declare readonly toggleAllTarget:HTMLInputElement;
  declare readonly shareCheckboxTargets:HTMLInputElement[];

  // Counters
  declare readonly sharedCounterTarget:HTMLElement;
  declare readonly selectedCounterTarget:HTMLElement;

  // Bulk Forms
  declare readonly bulkFormTargets:HTMLFormElement[];
  // Specific target for bulk update permission forms
  declare readonly bulkUpdateRoleFormTargets:HTMLFormElement[];
  declare readonly hiddenShareTargets:HTMLInputElement[];
  declare readonly bulkActionsTarget:HTMLElement;
  declare readonly defaultActionsTarget:HTMLElement;

  // Permission Buttons
  declare readonly userRowRoleTargets:HTMLButtonElement[];
  declare readonly bulkUpdateRoleLabelTarget:HTMLButtonElement;

  // Refresh when a user is invited
  shareCheckboxTargetConnected() {
    this.refresh();
  }

  // Refresh when a user is uninvited
  shareCheckboxTargetDisconnected() {
    this.refresh();
  }

  /*
    This allows for the Rails controller to be oblivious of the order in which the
    turbo stream actions must be declared. If all shares are selected and subsequently
    one is individually removed, the "Toggle All" checkbox should remain selected. If
    we only listen on the shares being added or removed, the event could fire before
    the new counter connects, making it appear not toggled.
   */
  toggleAllTargetConnected() {
    this.refresh();
  }

  // Refresh Bulk Update Label when a Role is updated inline
  // as the updated share might have been selected and the label
  // may no longer be correct
  userRowRoleTargetConnected() {
    if (this.checked.length === 0) {
      return;
    }

    this.updateBulkUpdateRoleLabelValue();
  }

  bulkUpdateRoleLabelValueChanged(current:string, _old:string) {
    const label = this.bulkUpdateRoleLabelTarget.querySelector('.Button-label') as HTMLElement;
    label.textContent = current;
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

  refresh() {
    const checkedSharesCount = this.checked.length;
    const sharesCount = this.shareCheckboxTargets.length;
    if (sharesCount === 0) {
      this.toggleAllTarget.checked = false;
    } else {
      this.toggleAllTarget.checked = checkedSharesCount === sharesCount;
    }

    if (this.checked.length === 0) {
      this.bulkActionsTarget.setAttribute('hidden', 'true');
      this.defaultActionsTarget.removeAttribute('hidden');
    } else {
      this.bulkActionsTarget.removeAttribute('hidden');
      this.defaultActionsTarget.setAttribute('hidden', 'true');
      this.updateBulkUpdateRoleLabelValue();
    }

    this.updateCounter();
  }

  // Private Methods

  private triggerInputEvent(checkbox:HTMLInputElement) {
    const event = new Event('input', { bubbles: false, cancelable: true });
    checkbox.dispatchEvent(event);
  }

  private updateBulkUpdateRoleLabelValue() {
    if (new Set(this.selectedPermissions).size > 1) {
      this.bulkUpdateRoleLabelValue = I18n.t('js.sharing.selection.mixed');
      this.bulkPermissionButtons.forEach((button) => button.setAttribute('aria-checked', 'false'));
    } else {
      this.bulkUpdateRoleLabelValue = this.selectedPermissions[0];
      const bulkUpdateRoleForm = this.bulkUpdateRoleFormTargets.find((form) => {
        return form.getAttribute('data-role-name') === this.bulkUpdateRoleLabelValue.trim();
      }) as HTMLFormElement;
      const button = bulkUpdateRoleForm.querySelector('button[type=submit]') as HTMLButtonElement;
      button.setAttribute('aria-checked', 'true');
    }
  }

  private updateCounter() {
    if (this.checked.length === 0) {
      this.showSharedCounter();
    } else {
      this.showSelectedCounter();
    }

    this.repopulateHiddenShares();
  }

  private showSharedCounter() {
    this.sharedCounterTarget.removeAttribute('hidden');
    this.selectedCounterTarget.setAttribute('hidden', 'true');
  }

  private showSelectedCounter() {
    this.selectedCounterTarget.textContent = I18n.t('js.sharing.selected_count', { count: this.checked.length });
    this.sharedCounterTarget.setAttribute('hidden', 'true');
    this.selectedCounterTarget.removeAttribute('hidden');
  }

  private repopulateHiddenShares() {
    this.hiddenShareTargets.forEach((hiddenInput) => hiddenInput.remove());

    this.bulkFormTargets.forEach((form) => {
      const hiddenShares = this.createHiddenShares();
      hiddenShares.forEach((hiddenShare) => form.appendChild(hiddenShare));
    });
  }

  private createHiddenShares() {
    return this.checked.map((checkbox) => {
      const hiddenInput = document.createElement('input');

      hiddenInput.type = 'hidden';
      hiddenInput.name = 'share_ids[]';
      hiddenInput.value = checkbox.value;
      hiddenInput.setAttribute('data-shares--bulk-selection-target', 'hiddenShare');

      return hiddenInput;
    });
  }

  private get bulkPermissionButtons():HTMLButtonElement[] {
    return this.bulkUpdateRoleFormTargets.map((bulkUpdateForm) => {
      return bulkUpdateForm.querySelector('button[type=submit]') as HTMLButtonElement;
    });
  }

  private get selectedPermissions() {
    return this.selectedRoleButtons.map((button) => {
      const label = button.querySelector('.Button-label') as HTMLElement;

      return label.textContent;
    }) as string[];
  }

  private get selectedRoleButtons() {
    const checkedShareIds = this.checked.map((checkbox) => checkbox.value);

    return this.userRowRoleTargets.filter((button) => {
      const shareId = button.getAttribute('data-share-id') as string;
      return checkedShareIds.includes(shareId);
    });
  }

  private get checked() {
    return this.shareCheckboxTargets.filter((checkbox) => checkbox.checked);
  }
}
