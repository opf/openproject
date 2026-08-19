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

export default class StorageFormController extends Controller {
  static targets = [
    'selectProviderType',
    'storageName',
    'storageUrl',
    'fieldset',
  ];

  static values = {
    oneDrivePlaceholder: String,
    nextcloudPlaceholder: String,
  };

  declare readonly selectProviderTypeTarget:HTMLSelectElement;
  declare readonly storageNameTarget:HTMLInputElement;
  declare readonly storageUrlTarget:HTMLElement;
  declare readonly fieldsetTarget:HTMLFieldSetElement;

  declare readonly nextcloudPlaceholderValue:string;
  declare readonly oneDrivePlaceholderValue:string;

  private urlFormField:HTMLElement;

  connect() {
    this.selectProviderTypeTarget.addEventListener('change', () => {
      this.updateForm();
    });

    this.urlFormField = this.storageUrlTarget;
    this.updateForm();
  }

  private updateForm() {
    const option = this.selectProviderTypeTarget.options[this.selectProviderTypeTarget.selectedIndex];

    switch (option.value) {
      case 'Storages::NextcloudStorage':
        this.storageNameTarget.placeholder = this.nextcloudPlaceholderValue;
        this.fieldsetTarget.append(this.urlFormField);
        break;
      case 'Storages::OneDriveStorage':
        this.storageNameTarget.placeholder = this.oneDrivePlaceholderValue;
        this.storageUrlTarget.remove();
        break;
      default:
        throw new Error(`unknown provider type ${option.value}`);
    }
  }
}
