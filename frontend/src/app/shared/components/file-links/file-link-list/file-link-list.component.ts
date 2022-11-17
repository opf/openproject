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
import {
  BehaviorSubject,
  Observable,
} from 'rxjs';
import { take } from 'rxjs/operators';
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
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  FilePickerModalComponent,
} from 'core-app/shared/components/file-links/file-picker-modal/file-picker-modal.component';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';

@Component({
  selector: 'op-file-link-list',
  templateUrl: './file-link-list.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public resource:HalResource;

  @Input() public storage:IStorage;

  fileLinks$:Observable<IFileLink[]>;

  allowEditing$:Observable<boolean>;

  disabled = false;

  storageType:string;

  storageInformation = new BehaviorSubject<StorageInformationBox[]>([]);

  showLinkFilesAction = new BehaviorSubject<boolean>(false);

  private isLoggedIn = false;

  private readonly storageTypeMap:Record<string, string> = {};

  text = {
    infoBox: {
      emptyStorageHeader: (storageType:string):string => this.i18n.t('js.storages.link_files_in_storage', { storageType }),
      emptyStorageContent: (storageType:string):string => this.i18n.t('js.storages.information.no_file_links', { storageType }),
      emptyStorageButton: (storageType:string):string => this.i18n.t('js.storages.open_storage', { storageType }),
      fileLinkErrorHeader: this.i18n.t('js.storages.information.live_data_error'),
      fileLinkErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.live_data_error_description', { storageType }),
      connectionErrorHeader: (storageType:string):string => this.i18n.t('js.storages.no_connection', { storageType }),
      connectionErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.connection_error', { storageType }),
      authorizationFailureHeader: (storageType:string):string => this.i18n.t('js.storages.login_to', { storageType }),
      authorizationFailureContent: (storageType:string):string => this.i18n.t('js.storages.information.not_logged_in', { storageType }),
      loginButton: (storageType:string):string => this.i18n.t('js.storages.login', { storageType }),
    },
    actions: {
      linkFile: (storageType:string):string => this.i18n.t('js.storages.link_files_in_storage', { storageType }),
      linkExisting: this.i18n.t('js.storages.link_existing_files'),
    },
  };

  public get storageFileLinkingEnabled():boolean {
    return this.configurationService.activeFeatureFlags.includes('storageFileLinking');
  }

  private get storageFilesLocation():string {
    return this.storage._links.open.href;
  }

  constructor(
    private readonly i18n:I18nService,
    private readonly cookieService:CookieService,
    private readonly opModalService:OpModalService,
    private readonly currentUserService:CurrentUserService,
    private readonly configurationService:ConfigurationService,
    private readonly fileLinkResourceService:FileLinksResourceService,
  ) {
    super();
  }

  ngOnInit():void {
    this.initializeStorageTypes();

    this.storageType = this.storageTypeMap[this.storage._links.type.href];

    this.disabled = this.storage._links.authorizationState.href !== storageConnected;

    this.fileLinks$ = this.fileLinkResourceService.collection(this.collectionKey);

    this.currentUserService.isLoggedIn$
      .pipe(this.untilDestroyed())
      .subscribe((isLoggedIn) => { this.isLoggedIn = isLoggedIn; });

    this.fileLinks$
      .pipe(this.untilDestroyed())
      .subscribe((fileLinks) => {
        if (isNewResource(this.resource)) {
          this.resource.fileLinks = { elements: fileLinks.map((a) => a._links?.self) };
        }

        this.storageInformation.next(this.instantiateStorageInformation(fileLinks));
        this.showLinkFilesAction.next(!this.disabled && fileLinks.length > 0);
      });

    this.allowEditing$ = this
      .currentUserService
      .hasCapabilities$('file_links/manage', (this.resource.project as unknown&{ id:string }).id);
  }

  public removeFileLink(fileLink:IFileLink):void {
    this.fileLinkResourceService.remove(this.collectionKey, fileLink);
  }

  public openStorageLocation():void {
    window.open(this.storageFilesLocation, '_blank');
  }

  public openLinkFilesDialog():void {
    this.fileLinks$
      .pipe(take(1))
      .subscribe((fileLinks) => {
        const locals = {
          storageType: this.storage._links.type.href,
          storageTypeName: this.storageType,
          storageName: this.storage.name,
          storageLocation: this.storageFilesLocation,
          storageLink: this.storage._links.self,
          addFileLinksHref: (this.resource.$links as unknown&{ addFileLink:IHalResourceLink }).addFileLink.href,
          collectionKey: this.collectionKey,
          fileLinks,
        };
        this.opModalService.show<FilePickerModalComponent>(FilePickerModalComponent, 'global', locals);
      });
  }

  private instantiateStorageInformation(fileLinks:IFileLink[]):StorageInformationBox[] {
    if (!this.isLoggedIn) {
      return [];
    }

    switch (this.storage._links.authorizationState.href) {
      case storageFailedAuthorization:
        return [this.failedAuthorizationInformation];
      case storageAuthorizationError:
        return [this.authorizationErrorInformation];
      case storageConnected:
        if (fileLinks.length === 0) {
          return [this.emptyStorageInformation];
        }
        if (fileLinks.filter((fileLink) => fileLink._links.permission?.href === fileLinkViewError).length > 0) {
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
      this.text.infoBox.authorizationFailureHeader(this.storageType),
      this.text.infoBox.authorizationFailureContent(this.storageType),
      [new StorageActionButton(
        this.text.infoBox.loginButton(this.storageType),
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
      this.text.infoBox.connectionErrorHeader(this.storageType),
      this.text.infoBox.connectionErrorContent(this.storageType),
      [],
    );
  }

  private get emptyStorageInformation():StorageInformationBox {
    return new StorageInformationBox(
      'add-link',
      this.text.infoBox.emptyStorageHeader(this.storageType),
      this.text.infoBox.emptyStorageContent(this.storageType),
      [new StorageActionButton(
        this.text.infoBox.emptyStorageButton(this.storageType),
        () => {
          window.open(this.storageFilesLocation, '_blank');
        },
      )],
    );
  }

  private get fileLinkErrorInformation():StorageInformationBox {
    return new StorageInformationBox(
      'error',
      this.text.infoBox.fileLinkErrorHeader,
      this.text.infoBox.fileLinkErrorContent(this.storageType),
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

  private initializeStorageTypes() {
    this.storageTypeMap[nextcloud] = this.i18n.t('js.storages.types.nextcloud');
  }
}
