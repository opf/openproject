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
 * Opens a confirmation dialog when the checkbox or radio button is changed to the trigger state.
 * The change is reverted unless it is confirmed with the dialog's submit button, which is marked
 * by `data-submit-dialog-id` as with Primer dialogs. For a radio button, reverting selects the
 * radio button of its group that was selected before.
 */
export default class InputConfirmationController extends Controller {
  static targets = ['input', 'dialog'];

  static values = {
    trigger: { type: String, default: 'unchecked' },
  };

  declare readonly inputTarget:HTMLInputElement;
  declare readonly dialogTarget:HTMLDialogElement;
  declare readonly triggerValue:'checked'|'unchecked';

  private confirmed = false;
  private previouslySelectedRadio:HTMLInputElement|undefined;

  connect():void {
    this.element.addEventListener('change', this.onChange);
  }

  disconnect():void {
    this.element.removeEventListener('change', this.onChange);
  }

  inputTargetConnected(input:HTMLInputElement):void {
    this.previouslySelectedRadio = this.radiosOf(input).find((radio) => radio.checked);
  }

  dialogTargetConnected(dialog:HTMLDialogElement):void {
    dialog.addEventListener('click', this.onDialogClick);
    dialog.addEventListener('close', this.onDialogClose);
  }

  dialogTargetDisconnected(dialog:HTMLDialogElement):void {
    dialog.removeEventListener('click', this.onDialogClick);
    dialog.removeEventListener('close', this.onDialogClose);
  }

  private onChange = (event:Event):void => {
    const changed = event.target as HTMLInputElement;

    if (changed === this.inputTarget && changed.checked === (this.triggerValue === 'checked')) {
      this.confirmed = false;
      this.dialogTarget.showModal();
    } else if (this.radiosOf(this.inputTarget).includes(changed)) {
      this.previouslySelectedRadio = changed;
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
    if (this.confirmed) {
      this.previouslySelectedRadio = this.radiosOf(this.inputTarget).find((radio) => radio.checked);
    } else if (this.inputTarget.type === 'radio') {
      this.inputTarget.checked = false;
      if (this.previouslySelectedRadio) {
        this.previouslySelectedRadio.checked = true;
      }
    } else {
      this.inputTarget.checked = !this.inputTarget.checked;
    }
  };

  private radiosOf(input:HTMLInputElement):HTMLInputElement[] {
    if (input.type !== 'radio') {
      return [];
    }

    return Array
      .from(this.element.querySelectorAll<HTMLInputElement>('input[type="radio"]'))
      .filter((radio) => radio.name === input.name);
  }
}
