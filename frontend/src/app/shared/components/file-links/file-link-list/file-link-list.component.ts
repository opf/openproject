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
  fileLinkViewAllowed, nextcloud,
  storageAuthorizationError,
  storageConnected,
  storageFailedAuthorization,
} from 'core-app/shared/components/file-links/file-links-constants.const';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { StorageActionButton } from 'core-app/shared/components/file-links/file-link-list/storage-action-button';

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

  informationBoxIcon:string;

  allowEditing = false;

  showInformationBox$ = new BehaviorSubject<boolean>(false);

  showFileLinks$ = new BehaviorSubject<boolean>(false);

  buttons = new BehaviorSubject<StorageActionButton[]>([]);

  private readonly storageTypeMap:Record<string, string> = {};

  text:{
    infoBox:{
      emptyStorageHeader:string,
      emptyStorageContent:string,
      emptyStorageButton:string,
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

    this.fileLinks$ = this.fileLinkResourceService.collection(this.collectionKey);

    this.fileLinks$
      .pipe(this.untilDestroyed())
      .subscribe((fileLinks) => {
        if (isNewResource(this.resource)) {
          this.resource.fileLinks = { elements: fileLinks.map((a) => a._links?.self) };
        }

        this.deriveStorageInformation(fileLinks.length);
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

  public isDisabled(fileLink:IFileLink):boolean {
    return fileLink._links.permission.href !== fileLinkViewAllowed;
  }

  private get collectionKey():string {
    return isNewResource(this.resource) ? 'new' : this.fileLinkSelfLink;
  }

  private get fileLinkSelfLink():string {
    const fileLinks = this.resource.fileLinks as unknown&{ href:string };
    return `${fileLinks.href}?filters=[{"storage":{"operator":"=","values":["${this.storage.id}"]}}]`;
  }

  private deriveStorageInformation(fileLinkCount:number):void {
    switch (this.storage._links.authorizationState.href) {
      case storageFailedAuthorization:
        this.setAuthorizationFailureState(fileLinkCount);
        break;
      case storageAuthorizationError:
        this.setConnectionErrorState();
        break;
      case storageConnected:
        if (fileLinkCount === 0) {
          this.setEmptyFileLinkListState();
        } else {
          this.showInformationBox$.next(false);
          this.showFileLinks$.next(true);
        }
        break;
      default:
        this.showInformationBox$.next(false);
        this.showFileLinks$.next(false);
    }
  }

  private setAuthorizationFailureState(fileLinkCount:number):void {
    this.prepareInformationBox(
      this.text.infoBox.authorizationFailureHeader,
      this.text.infoBox.authorizationFailureContent,
      'import',
    );

    this.buttons.next([
      new StorageActionButton(
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
      ),
    ]);

    this.showInformationBox$.next(true);
    this.showFileLinks$.next(fileLinkCount > 0);
  }

  private setAuthorizationCallbackCookie(nonce:string):void {
    this.cookieService.set(`oauth_state_${nonce}`, window.location.href, {
      path: '/',
    });
  }

  private static authorizationFailureActionUrl(baseUrl:string, nonce:string):string {
    return `${baseUrl}&state=${nonce}`;
  }

  private setConnectionErrorState():void {
    this.prepareInformationBox(
      this.text.infoBox.connectionErrorHeader,
      this.text.infoBox.connectionErrorContent,
      'remove-link',
    );

    this.buttons.next([]);

    this.showInformationBox$.next(true);
    this.showFileLinks$.next(false);
  }

  private setEmptyFileLinkListState():void {
    this.prepareInformationBox(
      this.text.infoBox.emptyStorageHeader,
      this.text.infoBox.emptyStorageContent,
      'add-link',
    );

    this.buttons.next([
      new StorageActionButton(
        this.text.infoBox.emptyStorageButton,
        () => {
          window.open(this.storageLocation, '_blank');
        },
      ),
      new StorageActionButton(
        this.text.infoBox.emptyStorageButton,
        () => {
          window.open(this.storageLocation, '_blank');
        },
      ),
    ]);

    this.showInformationBox$.next(true);
    this.showFileLinks$.next(false);
  }

  private prepareInformationBox(header:string, content:string, icon:string):void {
    this.informationBoxHeader = header;
    this.informationBoxContent = content;
    this.informationBoxIcon = icon;
  }

  private initializeLocales():void {
    const storageType = this.storageTypeMap[this.storage._links.type.href];
    this.text = {
      infoBox: {
        emptyStorageHeader: this.i18n.t('js.label_link_files_in_storage', { storageType }),
        emptyStorageContent: this.i18n.t('js.label_no_file_links', { storageType }),
        emptyStorageButton: this.i18n.t('js.label_open_storage', { storageType }),
        connectionErrorHeader: this.i18n.t('js.label_no_storage_connection', { storageType }),
        connectionErrorContent: this.i18n.t('js.label_storage_connection_error', { storageType }),
        authorizationFailureHeader: this.i18n.t('js.label_login_to_storage', { storageType }),
        authorizationFailureContent: this.i18n.t('js.label_storage_not_connected', { storageType }),
        loginButton: this.i18n.t('js.label_storage_login', { storageType }),
      },
      actions: {
        linkFile: this.i18n.t('js.label_link_files_in_storage', { storageType }),
      },
    };
  }

  private initializeStorageTypes() {
    this.storageTypeMap[nextcloud] = this.i18n.t('js.label_nextcloud');
  }
}
