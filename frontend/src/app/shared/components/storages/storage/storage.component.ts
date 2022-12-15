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
  ChangeDetectorRef,
  Component,
  Input,
  OnDestroy,
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
} from 'core-app/shared/components/storages/storages-constants.const';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { StorageActionButton } from 'core-app/shared/components/storages/storage-information/storage-action-button';
import {
  StorageInformationBox,
} from 'core-app/shared/components/storages/storage-information/storage-information-box';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import {
  FilePickerModalComponent,
} from 'core-app/shared/components/storages/file-picker-modal/file-picker-modal.component';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import {
  LocationPickerModalComponent,
} from 'core-app/shared/components/storages/location-picker-modal/location-picker-modal.component';

@Component({
  selector: 'op-storage',
  templateUrl: './storage.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StorageComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @Input() public resource:HalResource;

  @Input() public storage:IStorage;

  @Input() public allowUploading = true;

  @Input() public allowLinking = true;

  fileLinks$:Observable<IFileLink[]>;

  allowEditing$:Observable<boolean>;

  disabled = false;

  storageType:string;

  storageErrors = new BehaviorSubject<StorageInformationBox[]>([]);

  draggingOverDropZone = false;

  dragging = false;

  private isLoggedIn = false;

  private readonly storageTypeMap:Record<string, string> = {};

  text = {
    infoBox: {
      fileLinkErrorHeader: this.i18n.t('js.storages.information.live_data_error'),
      fileLinkErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.live_data_error_description', { storageType }),
      connectionErrorHeader: (storageType:string):string => this.i18n.t('js.storages.no_connection', { storageType }),
      connectionErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.connection_error', { storageType }),
      authorizationFailureHeader: (storageType:string):string => this.i18n.t('js.storages.login_to', { storageType }),
      authorizationFailureContent: (storageType:string):string => this.i18n.t('js.storages.information.not_logged_in', { storageType }),
      loginButton: (storageType:string):string => this.i18n.t('js.storages.login', { storageType }),
    },
    actions: {
      linkExisting: this.i18n.t('js.storages.link_existing_files'),
      uploadFile: this.i18n.t('js.storages.upload_files'),
    },
    dropBox: {
      uploadLabel: this.i18n.t('js.storages.upload_files'),
      dropFiles: ():string => this.i18n.t('js.storages.drop_files', { storageType: this.storageType }),
    },
    emptyList: ():string => this.i18n.t('js.storages.file_links.empty', { storageType: this.storageType }),
    openStorage: ():string => this.i18n.t('js.storages.open_storage', { storageType: this.storageType }),
  };

  public get storageFilesLocation():string {
    return this.storage._links.open.href;
  }

  constructor(
    private readonly i18n:I18nService,
    private readonly cdRef:ChangeDetectorRef,
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

        this.storageErrors.next(this.getStorageErrors(fileLinks));
      });

    this.allowEditing$ = this
      .currentUserService
      .hasCapabilities$('file_links/manage', (this.resource.project as unknown&{ id:string }).id);

    document.body.addEventListener('dragover', this.onGlobalDragOver.bind(this));
    document.body.addEventListener('dragleave', this.afterGlobalDragEnd.bind(this));
    document.body.addEventListener('drop', this.afterGlobalDragEnd.bind(this));
  }

  ngOnDestroy():void {
    document.body.removeEventListener('dragover', this.onGlobalDragOver.bind(this));
    document.body.removeEventListener('dragleave', this.afterGlobalDragEnd.bind(this));
    document.body.removeEventListener('drop', this.afterGlobalDragEnd.bind(this));
  }

  public removeFileLink(fileLink:IFileLink):void {
    this.fileLinkResourceService.remove(this.collectionKey, fileLink);
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

  public openSelectLocationDialog():void {
    const locals = {
      storageType: this.storage._links.type.href,
      storageTypeName: this.storageType,
      storageName: this.storage.name,
      storageLocation: this.storageFilesLocation,
      storageLink: this.storage._links.self,
    };
    this.opModalService.show<LocationPickerModalComponent>(LocationPickerModalComponent, 'global', locals);
  }

  private getStorageErrors(fileLinks:IFileLink[]):StorageInformationBox[] {
    if (!this.isLoggedIn) {
      return [];
    }

    switch (this.storage._links.authorizationState.href) {
      case storageFailedAuthorization:
        return [this.failedAuthorizationInformation];
      case storageAuthorizationError:
        return [this.authorizationErrorInformation];
      case storageConnected:
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
            window.location.href = StorageComponent.authorizationFailureActionUrl(
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

  public onDropFiles(event:DragEvent):void {
    if (event.dataTransfer === null) return;

    this.draggingOverDropZone = false;
    this.dragging = false;
  }

  public onDragOver(event:DragEvent):void {
    if (event.dataTransfer !== null && containsFiles(event.dataTransfer)) {
      // eslint-disable-next-line no-param-reassign
      event.dataTransfer.dropEffect = 'copy';
      this.draggingOverDropZone = true;
    }
  }

  public onDragLeave(_event:DragEvent):void {
    this.draggingOverDropZone = false;
  }

  public afterGlobalDragEnd():void {
    this.dragging = false;

    this.cdRef.detectChanges();
  }

  public onGlobalDragOver():void {
    this.dragging = true;

    this.cdRef.detectChanges();
  }
}

function containsFiles(dataTransfer:DataTransfer):boolean {
  return dataTransfer.types.indexOf('Files') >= 0;
}
