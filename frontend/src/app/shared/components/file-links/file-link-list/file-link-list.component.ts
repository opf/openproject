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
import { Observable } from 'rxjs';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

@Component({
  selector: 'op-file-link-list',
  templateUrl: './file-link-list.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public resource:HalResource;

  @Input() public storage:IStorage;

  fileLinks$:Observable<IFileLink[]>;

  informationBoxHeader:string;

  informationBoxContent:string;

  informationBoxButton:string;

  informationBoxIcon:string;

  showInformationBox = false;

  showFileLinks = false;

  private readonly storageTypeMap:{ [urn:string]:string; } = {
    'urn:openproject-org:api:v3:storages:Nextcloud': 'Nextcloud',
  };

  private text:{
    infoBox:{
      emptyStorageHeader:string,
      emptyStorageContent:string,
      emptyStorageButton:string,
      connectionErrorHeader:string,
      connectionErrorContent:string,
      authenticationFailureHeader:string,
      authenticationFailureContent:string,
      loginButton:string,
    }
  };

  constructor(
    private readonly i18n:I18nService,
    private readonly fileLinkResourceService:FileLinksResourceService,
  ) {
    super();
  }

  ngOnInit():void {
    this.initializeLocales();

    this.fileLinks$ = this.fileLinkResourceService.collection(this.collectionKey);

    this.fileLinks$
      .pipe(this.untilDestroyed())
      .subscribe((fileLinks) => {
        if (isNewResource(this.resource)) {
          this.resource.fileLinks = { elements: fileLinks.map((a) => a._links?.self) };
        }

        this.deriveStorageInformation(fileLinks.length);
      });
  }

  private get collectionKey():string {
    return isNewResource(this.resource) ? 'new' : this.fileLinkSelfLink;
  }

  private get fileLinkSelfLink():string {
    const fileLinks = this.resource.fileLinks as unknown&{ href:string };
    return `${fileLinks.href}?filters=[{"storage":{"operator":"=","values":["${this.storage.id}"]}}]`;
  }

  private deriveStorageInformation(fileLinkCount:number):void {
    switch (this.storage._links?.connectionState.href) {
      case 'urn:openproject-org:api:v3:storages:connection:FailedAuthentication':
        this.setAuthenticationFailureState();
        break;
      case 'urn:openproject-org:api:v3:storages:connection:Error':
        this.setConnectionErrorState();
        break;
      case 'urn:openproject-org:api:v3:storages:connection:Connected':
        if (fileLinkCount === 0) {
          this.setEmptyFileLinkListState();
        } else {
          this.showInformationBox = false;
          this.showFileLinks = true;
        }
        break;
      default:
        this.showInformationBox = false;
        this.showFileLinks = false;
    }
  }

  private setAuthenticationFailureState():void {
    this.informationBoxHeader = this.text.infoBox.authenticationFailureHeader;
    this.informationBoxContent = this.text.infoBox.authenticationFailureContent;
    this.informationBoxButton = this.text.infoBox.loginButton;
    this.informationBoxIcon = 'info1';
    this.showInformationBox = true;
    this.showFileLinks = true;
  }

  private setConnectionErrorState():void {
    this.informationBoxHeader = this.text.infoBox.connectionErrorHeader;
    this.informationBoxContent = this.text.infoBox.connectionErrorContent;
    this.informationBoxButton = this.text.infoBox.loginButton;
    this.informationBoxIcon = 'info1';
    this.showInformationBox = true;
    this.showFileLinks = false;
  }

  private setEmptyFileLinkListState():void {
    this.informationBoxHeader = this.text.infoBox.emptyStorageHeader;
    this.informationBoxContent = this.text.infoBox.emptyStorageContent;
    this.informationBoxButton = this.text.infoBox.emptyStorageButton;
    this.informationBoxIcon = 'info1';
    this.showInformationBox = true;
    this.showFileLinks = true;
  }

  private initializeLocales():void {
    const storageType = this.storageTypeMap[this.storage._links.type.href];
    this.text = {
      infoBox: {
        emptyStorageHeader: this.i18n.t('js.label_no_file_links_header', { storageType }),
        emptyStorageContent: this.i18n.t('js.label_no_file_links_content', { storageType }),
        emptyStorageButton: this.i18n.t('js.label_open_storage', { storageType }),
        connectionErrorHeader: this.i18n.t('js.label_no_storage_connection', { storageType }),
        connectionErrorContent: this.i18n.t('js.label_storage_connection_error', { storageType }),
        authenticationFailureHeader: this.i18n.t('js.label_login_to_storage', { storageType }),
        authenticationFailureContent: this.i18n.t('js.label_storage_not_connected', { storageType }),
        loginButton: this.i18n.t('js.label_storage_login', { storageType }),
      },
    };
  }
}
