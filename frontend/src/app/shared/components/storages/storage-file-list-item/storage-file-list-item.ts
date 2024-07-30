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

import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IFileIcon } from 'core-app/shared/components/storages/icons.mapping';
import { getIconForMimeType, isDirectory } from 'core-app/shared/components/storages/functions/storages.functions';

interface StorageFileListItemCheckbox {
  selected:boolean;
  changeSelection?:() => void;
}

export class StorageFileListItem {
  get name():string {
    return this.storageFile.name;
  }

  get mimeType():string|undefined {
    return this.storageFile.mimeType;
  }

  get createdByName():string|undefined {
    return this.storageFile.createdByName;
  }

  get timestamp():string|undefined {
    return this.storageFile.lastModifiedAt
      ? this.timezoneService.parseDatetime(this.storageFile.lastModifiedAt).fromNow()
      : undefined;
  }

  get icon():IFileIcon {
    return getIconForMimeType(this.storageFile.mimeType);
  }

  get isDirectory():boolean {
    return isDirectory(this.storageFile);
  }

  constructor(
    private readonly timezoneService:TimezoneService,
    private readonly storageFile:IStorageFile,
    public readonly disabled:boolean,
    public readonly isFirst:boolean,
    public readonly enterDirectory:() => void,
    public readonly isConstrained:boolean,
    public readonly tooltip?:string,
    public readonly checkbox?:StorageFileListItemCheckbox,
  ) {}
}
