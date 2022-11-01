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
  Input,
} from '@angular/core';

import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import {
  StorageFileListItem,
} from 'core-app/shared/components/file-links/storage-file-list-item/storage-file-list-item';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-storage-file-list-item]',
  templateUrl: './storage-file-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StorageFileListItemComponent {
  @Input() public content:StorageFileListItem;

  text = {
    alreadyLinkedFile: this.i18n.t('js.storages.file_links.already_linked_file'),
    alreadyLinkedDirectory: this.i18n.t('js.storages.file_links.already_linked_directory'),
  };

  get principal():PrincipalLike {
    return this.content.createdByName
      ? {
        name: this.content.createdByName,
        href: '/external_users/1',
      }
      : {
        name: 'Not Available',
        href: '/placeholder_users/1',
      };
  }

  get tooltip():string {
    return this.content.isDirectory ? this.text.alreadyLinkedDirectory : this.text.alreadyLinkedFile;
  }

  get getTooltipAlignment():SpotDropAlignmentOption {
    if (this.content.isFirst) {
      return SpotDropAlignmentOption.BottomLeft;
    }

    return SpotDropAlignmentOption.TopLeft;
  }

  constructor(
    private readonly i18n:I18nService,
  ) {}
}
