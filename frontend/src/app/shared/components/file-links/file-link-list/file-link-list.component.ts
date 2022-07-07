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
  OnInit,
} from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { CookieService } from 'ngx-cookie-service';
import { v4 as uuidv4 } from 'uuid';

import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { FileLinksResourceService } from 'core-app/core/state/file-links/file-links.service';
import {
  fileLinkViewError,
  nextcloud,
  storageAuthorizationError,
  storageConnected,
  storageFailedAuthorization,
} from 'core-app/shared/components/file-links/file-links-constants.const';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { StorageActionButton } from 'core-app/shared/components/file-links/storage-information/storage-action-button';
import {
  StorageInformationBox,
} from 'core-app/shared/components/file-links/storage-information/storage-information-box';

@Component({
  selector: 'op-file-link-list',
  templateUrl: './file-link-list.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public resource:HalResource;

  @Input() public storage:IStorage;

  fileLinks$:Observable<IFileLink[]>;

  allowEditing = false;

  disabled = false;

  storageInformation = new BehaviorSubject<StorageInformationBox[]>([]);

  private readonly storageTypeMap:Record<string, string> = {};

  text:{
    infoBox:{
      emptyStorageHeader:string,
      emptyStorageContent:string,
      emptyStorageButton:string,
      fileLinkErrorHeader:string,
      fileLinkErrorContent:string,
      connectionErrorHeader:string,
      connectionErrorContent:string,
      authorizationFailureHeader:string,
      authorizationFailureContent:string,
      loginButton:string,
    },
    actions:{
      linkFile:string,
    }
  };

  private get storageLocation():string {
    return this.storage._links.origin.href;
  }

  constructor(
    private readonly i18n:I18nService,
    private readonly fileLinkResourceService:FileLinksResourceService,
    private readonly currentUserService:CurrentUserService,
    private readonly cookieService:CookieService,
  ) {
    super();
  }

  ngOnInit():void {
    this.initializeStorageTypes();
    this.initializeLocales();

    this.disabled = this.storage._links.authorizationState.href !== storageConnected;

    this.fileLinks$ = this.fileLinkResourceService.collection(this.collectionKey);

    this.fileLinks$
      .pipe(this.untilDestroyed())
      .subscribe((fileLinks) => {
        if (isNewResource(this.resource)) {
          this.resource.fileLinks = { elements: fileLinks.map((a) => a._links?.self) };
        }

        this.storageInformation.next(this.instantiateStorageInformation(fileLinks));
      });

    this.currentUserService
      .hasCapabilities$('file_links/manage', (this.resource.project as unknown&{ id:string }).id)
      .pipe(this.untilDestroyed())
      .subscribe((value) => {
        this.allowEditing = value;
      });
  }

  public removeFileLink(fileLink:IFileLink):void {
    this.fileLinkResourceService.remove(this.collectionKey, fileLink);
  }

  public openStorageLocation():void {
    window.open(this.storageLocation, '_blank');
  }

  private instantiateStorageInformation(fileLinks:IFileLink[]):StorageInformationBox[] {
    switch (this.storage._links.authorizationState.href) {
      case storageFailedAuthorization:
        return [this.failedAuthorizationInformation];
      case storageAuthorizationError:
        return [this.authorizationErrorInformation];
      case storageConnected:
        if (fileLinks.length === 0) {
          return [this.emptyStorageInformation];
        }
        if (fileLinks.filter((fileLink) => fileLink._links.permission.href === fileLinkViewError).length > 0) {
          this.disabled = true;
          return [this.fileLinkErrorInformation];
        }
        return [];
      default:
        return [];
    }
  }

  private get failedAuthorizationInformation():StorageInformationBox {
    return new StorageInformationBox(
      'import',
      this.text.infoBox.authorizationFailureHeader,
      this.text.infoBox.authorizationFailureContent,
      [new StorageActionButton(
        this.text.infoBox.loginButton,
        () => {
          if (this.storage._links.authorize) {
            const nonce = uuidv4();
            this.setAuthorizationCallbackCookie(nonce);
            window.location.href = FileLinkListComponent.authorizationFailureActionUrl(
              this.storage._links.authorize.href,
              nonce,
            );
          } else {
            throw new Error('Authorize link is missing!');
          }
        },
      )],
    );
  }

  private get authorizationErrorInformation():StorageInformationBox {
    return new StorageInformationBox(
      'remove-link',
      this.text.infoBox.connectionErrorHeader,
      this.text.infoBox.connectionErrorContent,
      [],
    );
  }

  private get emptyStorageInformation():StorageInformationBox {
    return new StorageInformationBox(
      'add-link',
      this.text.infoBox.emptyStorageHeader,
      this.text.infoBox.emptyStorageContent,
      [new StorageActionButton(
        this.text.infoBox.emptyStorageButton,
        () => {
          window.open(this.storageLocation, '_blank');
        },
      )],
    );
  }

  private get fileLinkErrorInformation():StorageInformationBox {
    return new StorageInformationBox(
      'error',
      this.text.infoBox.fileLinkErrorHeader,
      this.text.infoBox.fileLinkErrorContent,
      [],
    );
  }

  private get collectionKey():string {
    return isNewResource(this.resource) ? 'new' : this.fileLinkSelfLink;
  }

  private get fileLinkSelfLink():string {
    const fileLinks = this.resource.fileLinks as unknown&{ href:string };
    return `${fileLinks.href}?filters=[{"storage":{"operator":"=","values":["${this.storage.id}"]}}]`;
  }

  private setAuthorizationCallbackCookie(nonce:string):void {
    this.cookieService.set(`oauth_state_${nonce}`, window.location.href, {
      path: '/',
    });
  }

  private static authorizationFailureActionUrl(baseUrl:string, nonce:string):string {
    return `${baseUrl}&state=${nonce}`;
  }

  private initializeLocales():void {
    const storageType = this.storageTypeMap[this.storage._links.type.href];
    this.text = {
      infoBox: {
        emptyStorageHeader: this.i18n.t('js.storages.link_files_in_storage', { storageType }),
        emptyStorageContent: this.i18n.t('js.storages.information.no_file_links', { storageType }),
        emptyStorageButton: this.i18n.t('js.storages.open_storage', { storageType }),
        fileLinkErrorHeader: this.i18n.t('js.storages.information.live_data_error'),
        fileLinkErrorContent: this.i18n.t('js.storages.information.live_data_error_description', { storageType }),
        connectionErrorHeader: this.i18n.t('js.storages.no_connection', { storageType }),
        connectionErrorContent: this.i18n.t('js.storages.information.connection_error', { storageType }),
        authorizationFailureHeader: this.i18n.t('js.storages.login_to', { storageType }),
        authorizationFailureContent: this.i18n.t('js.storages.information.not_logged_in', { storageType }),
        loginButton: this.i18n.t('js.storages.login', { storageType }),
      },
      actions: {
        linkFile: this.i18n.t('js.storages.link_files_in_storage', { storageType }),
      },
    };
  }

  private initializeStorageTypes() {
    this.storageTypeMap[nextcloud] = this.i18n.t('js.storages.types.nextcloud');
  }
}
