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
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFileLink, IFileLinkOriginData } from 'core-app/core/state/file-links/file-link.model';
import {
  getIconForMimeType,
} from 'core-app/shared/components/file-links/file-link-icons/file-link-list-item-icon.factory';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { IFileIcon } from 'core-app/shared/components/file-links/file-link-icons/icon-mappings';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-file-link-list-item]',
  templateUrl: './file-link-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListItemComponent implements OnInit, AfterViewInit {
  @Input() public resource:HalResource;

  @Input() public fileLink:IFileLink;

  @Input() public index:number;

  @Input() public allowEditing = false;

  @Output() public removeFileLink = new EventEmitter<void>();

  @ViewChild('avatar') avatar:ElementRef;

  public infoTimestampText:string;

  public fileLinkIcon:IFileIcon;

  public text = {
    title: {
      openFile: this.i18n.t('js.label_open_file_link'),
      openFileLocation: this.i18n.t('js.label_open_file_link_location'),
      removeFileLink: this.i18n.t('js.label_remove_file_link'),
    },
  };

  constructor(
    private readonly i18n:I18nService,
    private readonly timezoneService:TimezoneService,
    private readonly principalRendererService:PrincipalRendererService,
  ) {}

  private get originData():IFileLinkOriginData {
    return this.fileLink.originData;
  }

  ngOnInit():void {
    if (this.originData.lastModifiedAt) {
      this.infoTimestampText = this.timezoneService.parseDatetime(this.originData.lastModifiedAt).fromNow();
    }

    this.fileLinkIcon = getIconForMimeType(this.originData.mimeType);
  }

  ngAfterViewInit():void {
    if (this.originData.lastModifiedByName) {
      this.principalRendererService.render(
        this.avatar.nativeElement,
        { name: this.originData.lastModifiedByName, href: '/external_users/1' },
        { hide: true, link: false },
        { hide: false, size: 'mini' },
      );
    }
  }
}
