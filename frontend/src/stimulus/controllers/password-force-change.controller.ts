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

/**
 * Enforces that "force password change on next login" is checked and
 * non-editable whenever a plain-text password will be emailed to the user.
 */
export default class OpPasswordForceChangeController extends ApplicationController {
  static targets = ['assignRandomPassword', 'sendInformationCheckbox', 'forceChangeCheckbox'];

  declare readonly assignRandomPasswordTarget:HTMLInputElement;

  declare readonly sendInformationCheckboxTarget:HTMLInputElement;

  declare readonly hasAssignRandomPasswordTarget:boolean;

  declare readonly hasSendInformationCheckboxTarget:boolean;

  declare readonly forceChangeCheckboxTarget:HTMLInputElement;

  declare readonly hasForceChangeCheckboxTarget:boolean;

  private boundSyncSendInformation = this.syncSendInformation.bind(this);
  private boundSyncRandomPassword = this.syncRandomPassword.bind(this);

  assignRandomPasswordTargetConnected(target:HTMLInputElement) {
    target.addEventListener('change', this.boundSyncRandomPassword);
  }

  assignRandomPasswordTargetDisconnected(target:HTMLInputElement) {
    target.removeEventListener('change', this.boundSyncRandomPassword);
  }

  sendInformationCheckboxTargetConnected(target:HTMLInputElement) {
    target.addEventListener('change', this.boundSyncSendInformation);
  }

  sendInformationCheckboxTargetDisconnected(target:HTMLInputElement) {
    target.removeEventListener('change', this.boundSyncSendInformation);
  }

  private syncSendInformation():void {
    const assignedRandomChecked = this.hasAssignRandomPasswordTarget && this.assignRandomPasswordTarget.checked;
    if (!assignedRandomChecked && this.hasSendInformationCheckboxTarget) {
      this.forceChangeCheckboxTarget.checked = this.sendInformationCheckboxTarget.checked;
      this.forceChangeCheckboxTarget.disabled = this.sendInformationCheckboxTarget.checked;
    }
  }

  private syncRandomPassword():void {
    this.sendInformationCheckboxTarget.checked = this.assignRandomPasswordTarget.checked;
    this.sendInformationCheckboxTarget.disabled = this.assignRandomPasswordTarget.checked;
    this.forceChangeCheckboxTarget.checked = this.assignRandomPasswordTarget.checked;
    this.forceChangeCheckboxTarget.disabled = this.assignRandomPasswordTarget.checked;
  }
}
