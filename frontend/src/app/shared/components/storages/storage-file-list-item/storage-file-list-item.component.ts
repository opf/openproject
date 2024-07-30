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
  Component,
  Input,
} from '@angular/core';

import { PrincipalLike } from 'core-app/shared/components/principal/principal-types';
import {
  StorageFileListItem,
} from 'core-app/shared/components/storages/storage-file-list-item/storage-file-list-item';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-storage-file-list-item]',
  templateUrl: './storage-file-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StorageFileListItemComponent {
  @Input() public content:StorageFileListItem;

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

  get getTooltipAlignment():SpotDropAlignmentOption {
    if (this.content.isFirst) {
      return SpotDropAlignmentOption.BottomLeft;
    }

    return SpotDropAlignmentOption.TopLeft;
  }

  /**
   * This function enables an override of the click on the label for the storage file list items.
   *
   * Normal behaviour is, that the label click is associated with the first interactive element,
   * which usually should be the checkbox if available, or the "enterDirectory" icon button,
   * if no checkbox is available.
   *
   * With this override, the click on the label of a directory element WITH checkbox instead enters the directory.
   * But if directly targeting the checkbox, the item is checked instead.
   *
   * (WorkPackage #44965)
   */
  enterDirectoryOnLabel(event:MouseEvent):void {
    const isCheckboxTarget = (event.target as HTMLElement).className.includes('spot-checkbox');

    if (this.content.isDirectory && !isCheckboxTarget) {
      this.content.enterDirectory();
      event.preventDefault();
      event.stopPropagation();
    }
  }
}
