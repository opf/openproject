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

export default class AutomaticallyManagedProjectFoldersFormController extends Controller {
  static targets = [
    'applicationPasswordInput',
    'oneDriveInformationText',
    'submitButton',
  ];

  static values = {
    providerType: String,
    isAutomaticallyManaged: Boolean,
    doneCompleteLabel: String,
    doneCompleteWithoutLabel: String,
  };

  declare readonly applicationPasswordInputTarget:HTMLElement;
  declare readonly hasApplicationPasswordInputTarget:boolean;
  declare readonly oneDriveInformationTextTarget:HTMLElement;
  declare readonly hasOneDriveInformationTextTarget:boolean;
  declare readonly submitButtonTarget:HTMLElement;

  declare providerTypeValue:string;
  declare isAutomaticallyManagedValue:boolean;
  declare doneCompleteLabelValue:string;
  declare doneCompleteWithoutLabelValue:string;

  connect():void {
    // On first load if isAutomaticallyManaged is true, show the applicationPasswordInput
    this.toggleApplicationPasswordDisplay(this.isAutomaticallyManagedValue);
  }

  public updateDisplay(evt:Event):void {
    this.toggleApplicationPasswordDisplay((evt.target as HTMLInputElement).checked);
  }

  toggleApplicationPasswordDisplay(automaticManagementEnabled:boolean):void {
    switch (this.providerTypeValue) {
      case 'Storages::NextcloudStorage':
        if (!this.hasApplicationPasswordInputTarget) {
          return;
        }

        if (automaticManagementEnabled) {
          this.applicationPasswordInputTarget.classList.remove('d-none');
          this.submitButtonTarget.textContent = this.doneCompleteLabelValue;
        } else {
          this.applicationPasswordInputTarget.classList.add('d-none');
          this.submitButtonTarget.textContent = this.doneCompleteWithoutLabelValue;
        }

        break;
      case 'Storages::OneDriveStorage':
        if (!this.hasOneDriveInformationTextTarget) {
          return;
        }

        if (automaticManagementEnabled) {
          this.oneDriveInformationTextTarget.classList.remove('d-none');
        } else {
          this.oneDriveInformationTextTarget.classList.add('d-none');
        }

        break;
      default:
        throw new Error('unknown storage provider type');
    }
  }
}
