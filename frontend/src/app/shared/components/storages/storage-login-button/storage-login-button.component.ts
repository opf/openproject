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

import { ChangeDetectionStrategy, Component, ElementRef, Input, OnInit } from '@angular/core';
import { CookieService } from 'ngx-cookie-service';
import { v4 as uuidv4 } from 'uuid';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IStorageLoginInput } from 'core-app/shared/components/storages/storage-login-button/storage-login-input';
import { storageLocaleString } from 'core-app/shared/components/storages/functions/storages.functions';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';


@Component({
  selector: 'op-storage-login-button',
  templateUrl: 'storage-login-button.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StorageLoginButtonComponent implements OnInit {
  @Input() input:IStorageLoginInput;

  label:string;

  constructor(
    public elementRef:ElementRef,
    private readonly i18n:I18nService,
    private readonly cookieService:CookieService,
  ) {
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    const storageType = this.i18n.t(storageLocaleString(this.input.storageType));
    this.label = this.i18n.t('js.storages.login', { storageType });
  }

  public login():void {
    const nonce = uuidv4();
    this.setAuthorizationCallbackCookie(nonce);
    window.location.href = StorageLoginButtonComponent.authorizationFailureActionUrl(this.input.authorizationLink.href, nonce);
  }

  private setAuthorizationCallbackCookie(nonce:string):void {
    this.cookieService.set(
      `oauth_state_${nonce}`,
      JSON.stringify({ href: window.location.href, storageId: this.input.storageId }),
      {
        path: '/',
        expires: 1/24, // roughly 1 hour
      },
    );
  }

  private static authorizationFailureActionUrl(baseUrl:string, nonce:string):string {
    return `${baseUrl}&state=${nonce}`;
  }
}
