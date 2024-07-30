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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Inject,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import { isDirectory, storageLocaleString } from 'core-app/shared/components/storages/functions/storages.functions';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import {
  StorageFileListItem,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import {
  FilePickerBaseModalComponent,
} from 'core-app/shared/components/storages/file-picker-base-modal/file-picker-base-modal.component';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  templateUrl: 'location-picker-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LocationPickerModalComponent extends FilePickerBaseModalComponent {
  public submitted = false;

  public readonly text = {
    header: this.i18n.t('js.storages.select_location'),
    alertNoAccess: this.i18n.t('js.storages.files.project_folder_no_access'),
    alertNoManagedProjectFolder: this.i18n.t('js.storages.files.managed_project_folder_not_available'),
    alertNoAccessToManagedProjectFolder: this.i18n.t('js.storages.files.managed_project_folder_no_access'),
    content: {
      empty: this.i18n.t('js.storages.files.empty_folder'),
      emptyHint: this.i18n.t('js.storages.files.empty_folder_location_hint'),
      noConnection: (storageType:string) => this.i18n.t('js.storages.no_connection', { storageType }),
      noConnectionHint: (storageType:string) => this.i18n.t('js.storages.information.connection_error', { storageType }),
    },
    buttons: {
      submit: this.i18n.t('js.storages.choose_location'),
      submitEmptySelection: this.i18n.t('js.storages.file_links.selection_none'),
      cancel: this.i18n.t('js.button_cancel'),
      selectAll: this.i18n.t('js.storages.file_links.select_all'),
    },
    tooltip: {
      directory_not_writeable: this.i18n.t('js.storages.files.directory_not_writeable'),
      file_not_selectable: this.i18n.t('js.storages.files.file_not_selectable_location'),
    },
  };

  public get location():IStorageFile {
    return this.currentDirectory;
  }

  public get storageType():string {
    return this.i18n.t(storageLocaleString(this.storage._links.type.href));
  }

  public get filesAtLocation():IStorageFile[] {
    return this.storageFiles$.getValue();
  }

  public get canChooseLocation():boolean {
    if (!this.currentDirectory) {
      return false;
    }

    return this.currentDirectory.permissions.some((value) => value === 'writeable');
  }

  public get alertText():Observable<string> {
    return this.showAlert
      .pipe(
        map((alert) => {
          switch (alert) {
            case 'noAccess':
              return this.text.alertNoAccess;
            case 'managedFolderNoAccess':
              return this.text.alertNoAccessToManagedProjectFolder;
            case 'managedFolderNotFound':
              return this.text.alertNoManagedProjectFolder;
            case 'none':
              return '';
            default:
              throw new Error('unknown alert type');
          }
        }),
      );
  }

  constructor(
    @Inject(OpModalLocalsToken) public locals:OpModalLocalsMap,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    protected sortFilesPipe:SortFilesPipe,
    protected readonly storageFilesResourceService:StorageFilesResourceService,
    private readonly i18n:I18nService,
    private readonly timezoneService:TimezoneService,
  ) {
    super(
      locals,
      elementRef,
      cdRef,
      sortFilesPipe,
      storageFilesResourceService,
    );
  }

  public chooseLocation():void {
    this.submitted = true;
    this.service.close();
  }

  protected storageFileToListItem(file:IStorageFile, index:number):StorageFileListItem {
    return new StorageFileListItem(
      this.timezoneService,
      file,
      !isDirectory(file),
      index === 0,
      this.enterDirectoryCallback(file),
      this.isConstrained(file),
      this.tooltip(file),
      undefined,
    );
  }

  private isConstrained(file:IStorageFile):boolean {
    return !file.permissions.some((permission) => permission === 'writeable');
  }

  private tooltip(file:IStorageFile):string|undefined {
    if (isDirectory(file)) {
      return file.permissions.some((permission) => permission === 'writeable')
        ? undefined
        : this.text.tooltip.directory_not_writeable;
    }

    return this.text.tooltip.file_not_selectable;
  }
}
