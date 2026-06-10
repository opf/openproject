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

import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IStorage } from 'core-app/core/state/storages/storage.model';
import { IFileLink } from 'core-app/core/state/file-links/file-link.model';
import { StorageInformationBox } from 'core-app/shared/components/storages/storage-information/storage-information-box';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { storageLocaleString } from 'core-app/shared/components/storages/functions/storages.functions';
import {
  fileLinkStatusError,
  storageAuthorizationError,
  storageConnected,
  storageNotConnected,
  storageFailedAuthorization,
} from 'core-app/shared/components/storages/storages-constants.const';

@Injectable()
export class StorageInformationService {
  private readonly i18n = inject(I18nService);
  private readonly currentUserService = inject(CurrentUserService);

  private text = {
    fileLinkErrorHeader: this.i18n.t('js.storages.information.live_data_error'),
    fileLinkErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.live_data_error_description', { storageType }),
    authenticationErrorHeader: (storageType:string):string => this.i18n.t('js.storages.authentication_error', { storageType }),
    authenticationErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.authentication_error', { storageType }),
    connectionErrorHeader: (storageType:string):string => this.i18n.t('js.storages.no_connection', { storageType }),
    connectionErrorContent: (storageType:string):string => this.i18n.t('js.storages.information.connection_error', { storageType }),
    notConnectedHeader: (storageType:string):string => this.i18n.t('js.storages.login_to', { storageType }),
    notConnectedContent: (storageType:string):string => this.i18n.t('js.storages.information.not_logged_in', { storageType }),
    loginButton: (storageType:string):string => this.i18n.t('js.storages.login', { storageType }),
    suggestLogout: this.i18n.t('js.storages.information.suggest_logout'),
    suggestRelink: this.i18n.t('js.storages.information.suggest_relink'),
  };

  public storageInformation(storage:IStorage, fileLinks:IFileLink[]):Observable<StorageInformationBox[]> {
    return this.currentUserService.isLoggedIn$
      .pipe(
        map((loggedIn) => {
          if (!loggedIn) {
            return [];
          }

          const storageType = this.i18n.t(storageLocaleString(storage._links.type.href));

          switch (storage._links.authorizationState.href) {
            case storageFailedAuthorization:
              return [this.failedAuthorizationInformation(storage, storageType)];
            case storageNotConnected:
              return [this.notConnectedInformation(storage, storageType)];
            case storageAuthorizationError:
              return [this.authorizationErrorInformation(storageType)];
            case storageConnected:
              if (this.hasFileLinkViewErrors(fileLinks)) {
                return [this.fileLinkErrorInformation(storageType)];
              }
              return [];
            default:
              return [];
          }
        }),
      );
  }

  private notConnectedInformation(storage:IStorage, storageType:string):StorageInformationBox {
    if (!storage._links.authorize) {
      // user should authenticate through SSO, but is not yet linked, that's an error
      return this.failedAuthorizationInformation(storage, storageType);
    }

    return new StorageInformationBox(
      'import',
      this.text.notConnectedHeader(storageType),
      this.text.notConnectedContent(storageType),
      {
        storageId: storage.id,
        storageType: storage._links.type.href,
        authorizationLink: storage._links.authorize,
      },
    );
  }

  private failedAuthorizationInformation(storage:IStorage, storageType:string):StorageInformationBox {
    const suggestion = storage._links.authorize ? this.text.suggestRelink : this.text.suggestLogout;
    return new StorageInformationBox(
      'error',
      this.text.authenticationErrorHeader(storageType),
      `${this.text.authenticationErrorContent(storageType)} ${suggestion}`,
      storage._links.authorize && {
        storageId: storage.id,
        storageType: storage._links.type.href,
        authorizationLink: storage._links.authorize,
      },
    );
  }

  private authorizationErrorInformation(storageType:string):StorageInformationBox {
    return new StorageInformationBox(
      'remove-link',
      this.text.connectionErrorHeader(storageType),
      this.text.connectionErrorContent(storageType),
    );
  }

  private fileLinkErrorInformation(storageType:string):StorageInformationBox {
    return new StorageInformationBox(
      'error',
      this.text.fileLinkErrorHeader,
      this.text.fileLinkErrorContent(storageType),
    );
  }

  private hasFileLinkViewErrors(fileLinks:IFileLink[]):boolean {
    return fileLinks.filter((fileLink) => fileLink._links.status?.href === fileLinkStatusError).length > 0;
  }
}
