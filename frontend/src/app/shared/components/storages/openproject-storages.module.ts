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

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CookieService } from 'ngx-cookie-service';

import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { OpSpotModule } from 'core-app/spot/spot.module';

import { StorageComponent } from 'core-app/shared/components/storages/storage/storage.component';
import {
  FileLinkListItemComponent,
} from 'core-app/shared/components/storages/file-link-list-item/file-link-list-item.component';
import {
  StorageInformationComponent,
} from 'core-app/shared/components/storages/storage-information/storage-information.component';
import {
  FilePickerModalComponent,
} from 'core-app/shared/components/storages/file-picker-modal/file-picker-modal.component';
import { OpSharedModule } from 'core-app/shared/shared.module';
import { SortFilesPipe } from 'core-app/shared/components/storages/pipes/sort-files.pipe';
import {
  StorageFileListItemComponent,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item.component';
import {
  LocationPickerModalComponent,
} from 'core-app/shared/components/storages/location-picker-modal/location-picker-modal.component';
import {
  LoadingFileListComponent,
} from 'core-app/shared/components/storages/loading-file-list/loading-file-list.component';
import {
  UploadConflictModalComponent,
} from 'core-app/shared/components/storages/upload-conflict-modal/upload-conflict-modal.component';
import {
  StorageInformationService,
} from 'core-app/shared/components/storages/storage-information/storage-information.service';
import {
  StorageLoginButtonComponent,
} from 'core-app/shared/components/storages/storage-login-button/storage-login-button.component';

@NgModule({
  imports: [
    CommonModule,
    IconModule,
    OpSpotModule,
    OpSharedModule,
  ],
  declarations: [
    StorageComponent,
    StorageLoginButtonComponent,
    FileLinkListItemComponent,
    FilePickerModalComponent,
    LocationPickerModalComponent,
    LoadingFileListComponent,
    StorageInformationComponent,
    StorageFileListItemComponent,
    SortFilesPipe,
    UploadConflictModalComponent,
  ],
  exports: [
    StorageComponent,
  ],
  providers: [
    SortFilesPipe,
    CookieService,
    StorageInformationService,
  ],
})
export class OpenprojectStoragesModule {}
