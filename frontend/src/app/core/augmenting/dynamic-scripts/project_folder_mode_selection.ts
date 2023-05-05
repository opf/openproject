// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { from, Observable, switchMap } from 'rxjs';
import { filter, map } from 'rxjs/operators';

import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import {
  LocationPickerModalComponent,
} from 'core-app/shared/components/storages/location-picker-modal/location-picker-modal.component';

interface PartialStorage {
  name:string,
  id:string,
  _links:{
    self:{ href:string },
    type:{ href:string },
  }
}

const projectFolderModeRadioButtons = document.querySelectorAll('input[name="storages_project_storage[project_folder_mode]"]');

const projectFolderSelectionSection = document.getElementById('storages_manual_folder_selection') as HTMLElement;
const manualProjectFolderModeInput = document.getElementById('storages_project_storage_project_folder_mode_manual') as HTMLInputElement;
const openLocationPickerButton = document.getElementById('open_location_picker_button') as HTMLButtonElement|null;
const storageSelector = document.getElementById('storages_project_storage_storage_id') as HTMLSelectElement|null;
const storageSpan = document.getElementById('active_storage') as HTMLSpanElement|null;
const storageIdInput = document.getElementById('storages_project_storage_project_folder_id') as HTMLInputElement|null;
const storageNameInput = document.getElementById('storages_project_storage_project_folder_name') as HTMLInputElement|null;

function modalService():Observable<OpModalService> {
  return from(window.OpenProject.getPluginContext())
    .pipe(map((pluginContext) => pluginContext.services.opModalService));
}

function parseStorageData():PartialStorage {
  let json = '';
  if (storageSelector !== null) {
    const selectedStorageOption = storageSelector.options[storageSelector.selectedIndex];
    json = selectedStorageOption.dataset.storage as string;
  } else if (storageSpan !== null) {
    json = storageSpan.dataset.storage as string;
  } else {
    throw new Error('No storage data available.');
  }

  const data = JSON.parse(json) as unknown&{ id:string, name:string, href:string, type:string };

  return {
    id: data.id,
    name: data.name,
    _links: {
      self: { href: data.href },
      type: { href: data.type },
    },
  };
}

// Show the manual folder selection section if the manual radio button is checked
if (manualProjectFolderModeInput !== null
  && manualProjectFolderModeInput.checked
  && projectFolderSelectionSection !== null
) {
  projectFolderSelectionSection.style.display = 'flex';
}

projectFolderModeRadioButtons.forEach((radio:HTMLInputElement) => {
  radio.onchange = () => {
    // If the manual radio button is selected, show the manual folder selection section
    if (radio.value === 'manual') {
      projectFolderSelectionSection.style.display = 'flex';
    } else {
      projectFolderSelectionSection.style.display = 'none';
    }
  };
});

if (openLocationPickerButton !== null) {
  openLocationPickerButton.onclick = () => {
    const locals = {
      projectFolderId: null,
      storage: parseStorageData(),
    };
    modalService()
      .pipe(
        switchMap((service) => service.show(LocationPickerModalComponent, 'global', locals)),
        switchMap((modal) => modal.closingEvent),
        filter((modal) => modal.submitted),
      )
      .subscribe((modal) => {
        if (storageIdInput !== null && storageNameInput !== null) {
          storageIdInput.value = modal.location.id as string;
          storageNameInput.value = modal.location.name;
        }
      });
  };
}
