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
import { from, Observable } from 'rxjs';
import { filter, map, switchMap } from 'rxjs/operators';

import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  LocationPickerModalComponent,
} from 'core-app/shared/components/storages/location-picker-modal/location-picker-modal.component';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';

export default class ProjectStorageFormController extends Controller {
  static targets = [
    'projectFolderSection',
    'projectFolderIdInput',
    'projectFolderIdValidation',
    'selectedFolderText',
    'storage',
    'storageSelector',
  ];

  static values = {
    folderMode: String,
    placeholderFolderName: String,
  };

  declare folderModeValue:string;

  declare placeholderFolderNameValue:string;

  declare readonly storageTargets:HTMLElement[];

  declare readonly storageSelectorTarget:HTMLSelectElement;

  declare readonly hasStorageSelectorTarget:boolean;

  declare readonly projectFolderSectionTarget:HTMLElement;

  declare readonly projectFolderIdInputTarget:HTMLInputElement;

  declare readonly projectFolderIdValidationTarget:HTMLSpanElement;

  declare readonly selectedFolderTextTarget:HTMLSpanElement;

  declare readonly hasProjectFolderSectionTarget:boolean;

  connect():void {
    this.toggleFolderDisplay(this.folderModeValue);
    this.selectedFolderTextTarget.innerText = this.placeholderFolderNameValue;

    const href = this.projectFolderHref;
    if (href !== null) {
      void fetch(href)
        .then((data) => data.json())
        .then((file:IStorageFile) => {
          this.selectedFolderTextTarget.innerText = file.name;
        });
    }
  }

  selectProjectFolder(_evt:Event):void {
    const locals = {
      projectFolderHref: this.projectFolderHref,
      storage: this.storage,
    };

    this.modalService
      .pipe(
        switchMap((service) => service.show(LocationPickerModalComponent, 'global', locals)),
        switchMap((modal) => modal.closingEvent),
        filter((modal) => modal.submitted),
      )
      .subscribe((modal) => {
        this.projectFolderIdValidationTarget.style.display = 'none';
        this.selectedFolderTextTarget.innerText = modal.location.name;
        this.projectFolderIdInputTarget.value = modal.location.id as string;
      });
  }

  updateDisplay(evt:InputEvent):void {
    if (!this.hasProjectFolderSectionTarget) {
      return;
    }

    this.toggleFolderDisplay((evt.target as HTMLInputElement).value);
  }

  private get modalService():Observable<OpModalService> {
    return from(window.OpenProject.getPluginContext())
      .pipe(map((pluginContext) => pluginContext.services.opModalService));
  }

  private get storage():IStorage {
    const storageElement = this.hasStorageSelectorTarget
      ? this.storageSelectorTarget.options[this.storageSelectorTarget.selectedIndex]
      : this.storageTargets[0];

    return JSON.parse(storageElement.dataset.storage as string) as IStorage;
  }

  private get projectFolderHref():string|null {
    const projectFolderId = this.projectFolderIdInputTarget.value;

    if (projectFolderId.length === 0) {
      return null;
    }

    return `${this.storage._links.self.href}/files/${projectFolderId}`;
  }

  private toggleFolderDisplay(value:string):void {
    // If the manual radio button is selected, show the manual folder selection section
    if (value === 'manual') {
      this.projectFolderSectionTarget.style.display = 'flex';
    } else {
      this.projectFolderSectionTarget.style.display = 'none';
    }
  }
}
