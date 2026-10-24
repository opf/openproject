//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';

/**
 * Opens a confirmation dialog when the checkbox is changed to the trigger state. The checkbox is
 * changed back unless the change is confirmed with the dialog's submit button, which is marked by
 * `data-submit-dialog-id` as with Primer dialogs.
 */
export default class CheckboxConfirmationController extends Controller {
  static targets = ['checkbox', 'dialog'];

  static values = {
    trigger: { type: String, default: 'unchecked' },
  };

  declare readonly checkboxTarget:HTMLInputElement;
  declare readonly dialogTarget:HTMLDialogElement;
  declare readonly triggerValue:'checked'|'unchecked';

  private confirmed = false;

  checkboxTargetConnected(checkbox:HTMLInputElement):void {
    checkbox.addEventListener('change', this.onChange);
  }

  checkboxTargetDisconnected(checkbox:HTMLInputElement):void {
    checkbox.removeEventListener('change', this.onChange);
  }

  dialogTargetConnected(dialog:HTMLDialogElement):void {
    dialog.addEventListener('click', this.onDialogClick);
    dialog.addEventListener('close', this.onDialogClose);
  }

  dialogTargetDisconnected(dialog:HTMLDialogElement):void {
    dialog.removeEventListener('click', this.onDialogClick);
    dialog.removeEventListener('close', this.onDialogClose);
  }

  private onChange = ():void => {
    if (this.checkboxTarget.checked === (this.triggerValue === 'checked')) {
      this.confirmed = false;
      this.dialogTarget.showModal();
    }
  };

  // Primer closes the dialog on its own when the submit button is clicked.
  private onDialogClick = (event:MouseEvent):void => {
    if (!(event.target as Element).closest('[data-submit-dialog-id]')) {
      return;
    }

    this.confirmed = true;
    if (this.dialogTarget.open) {
      this.dialogTarget.close();
    }
  };

  private onDialogClose = ():void => {
    if (!this.confirmed) {
      this.checkboxTarget.checked = !this.checkboxTarget.checked;
    }
  };
}
