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
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnInit, Output,
  ViewChild,
} from '@angular/core';

import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IFileIcon } from 'core-app/shared/components/file-links/file-link-icons/icon-mappings';
import {
  getIconForMimeType,
} from 'core-app/shared/components/file-links/file-link-icons/file-link-list-item-icon.factory';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { isDirectory } from 'core-app/shared/components/file-links/file-link-icons/file-icons.helper';
import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-storage-file-list-item]',
  templateUrl: './storage-file-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StorageFileListItemComponent implements OnInit {
  @Input() public storageFile:IStorageFile;

  @Input() public selected = false;

  @Output() public changeSelection = new EventEmitter();

  @ViewChild('avatar') avatar:ElementRef;

  infoTimestampText:string;

  fileLinkIcon:IFileIcon;

  showDetails:boolean;

  get principal():PrincipalLike {
    return this.storageFile.createdByName
      ? {
        name: this.storageFile.createdByName,
        href: '/external_users/1',
      }
      : {
        name: 'Not Available',
        href: '/placeholder_users/1',
      };
  }

  constructor(private readonly timezoneService:TimezoneService) {}

  ngOnInit():void {
    if (this.storageFile.lastModifiedAt) {
      this.infoTimestampText = this.timezoneService.parseDatetime(this.storageFile.lastModifiedAt).fromNow();
    }

    this.fileLinkIcon = getIconForMimeType(this.storageFile.mimeType);

    this.showDetails = !isDirectory(this.storageFile.mimeType);
  }
}
