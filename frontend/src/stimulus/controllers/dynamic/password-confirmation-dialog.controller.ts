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

import { ApplicationController } from 'stimulus-use';

export default class PasswordConfirmationDialogController extends ApplicationController {
  private formListener:(evt:SubmitEvent) => unknown = this.onFormSubmit.bind(this);
  private dialogListener:(evt:Event) => unknown = this.onDialogClose.bind(this);
  private passwordInputListener:(evt:Event) => unknown = this.onPasswordInput.bind(this);

  static targets = [
    'form',
    'passwordInput',
    'submitButton',
  ];

  private dialog:HTMLDialogElement;
  declare readonly formTarget:HTMLFormElement;
  declare readonly passwordInputTarget:HTMLInputElement;
  declare readonly submitButtonTarget:HTMLButtonElement;

  connect() {
    super.connect();

    this.dialog = this.element as HTMLDialogElement;

    this.submitButtonTarget.disabled = true;

    this.dialog.addEventListener('close', this.dialogListener);
    this.formTarget.addEventListener('submit', this.formListener);
    this.passwordInputTarget.addEventListener('input', this.passwordInputListener);
  }

  disconnect() {
    super.disconnect();

    this.dialog.removeEventListener('close', this.dialogListener);
    this.formTarget.removeEventListener('submit', this.formListener);
    this.passwordInputTarget.removeEventListener('input', this.passwordInputListener);
  }

  private onFormSubmit(event:SubmitEvent) {
    event.preventDefault();

    document.dispatchEvent(new CustomEvent('password-confirmation-dialog:submit', { detail: this.passwordInputTarget.value }));
    this.dialog.close();

    return false;
  }

  private onPasswordInput(_event:Event) {
    this.submitButtonTarget.disabled = this.passwordInputTarget.value.length === 0;
  }

  private onDialogClose(_event:Event) {
    document.dispatchEvent(new Event('password-confirmation-dialog:close'));
  }
}
