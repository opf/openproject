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
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import {
  getIconForMimeType,
  IFileLinkListItemIcon,
} from 'core-app/shared/components/file-links/file-link-list/file-link-list-item-icon.factory';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

@Component({
  selector: 'op-file-link-list-item',
  templateUrl: './file-link-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListItemComponent implements OnInit {
  @Input() public resource:HalResource;

  @Input() public fileLink:IFileLink;

  @Input() public index:number;

  public infoTimestampText:string;

  public fileLinkIcon:IFileLinkListItemIcon;

  constructor(
    private readonly i18n:I18nService,
    private readonly timezoneService:TimezoneService,
  ) {}

  ngOnInit():void {
    if (this.fileLink.originData.lastModifiedAt) {
      const date = this.timezoneService.formattedDate(this.fileLink.originData.lastModifiedAt);
      this.infoTimestampText = this.i18n.t('js.label_modified_at', { date });
    }

    this.fileLinkIcon = getIconForMimeType(this.fileLink.originData.mimeType);
  }
}
