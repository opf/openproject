// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
import { Breadcrumb } from 'core-app/spot/components/breadcrumbs/breadcrumbs-content';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import { isDirectory } from 'core-app/shared/components/storages/functions/storages.functions';
import { StorageFilesResourceService } from 'core-app/core/state/storage-files/storage-files.service';
import {
  StorageFileListItem,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import {
  FilePickerBaseModalComponent,
} from 'core-app/shared/components/storages/file-picker-base-modal.component.ts/file-picker-base-modal.component';

@Component({
  templateUrl: 'location-picker-modal.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LocationPickerModalComponent extends FilePickerBaseModalComponent {
  public submitted = false;

  public readonly text = {
    header: this.i18n.t('js.storages.select_location'),
    buttons: {
      openStorage: ():string => this.i18n.t('js.storages.open_storage', { storageType: this.locals.storageTypeName as string }),
      submit: this.i18n.t('js.storages.choose_location'),
      submitEmptySelection: this.i18n.t('js.storages.file_links.selection_none'),
      cancel: this.i18n.t('js.button_cancel'),
      selectAll: this.i18n.t('js.storages.file_links.select_all'),
    },
  };

  public get canChooseLocation():boolean {
    return this.breadcrumbs.crumbs.length > 1;
  }

  public location = '/';

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
    const isFolder = isDirectory(file.mimeType);
    const enterDirectoryCallback = isFolder ? this.enterDirectoryCallback(file) : undefined;

    return new StorageFileListItem(
      this.timezoneService,
      file,
      !isFolder,
      index === 0,
      undefined,
      undefined,
      enterDirectoryCallback,
    );
  }

  protected changeLevel(parent:string|null, crumbs:Breadcrumb[]):void {
    this.location = parent === null ? '/' : parent;
    super.changeLevel(parent, crumbs);
  }
}
