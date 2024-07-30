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

import { Injectable } from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';

/*
 * This service conditionally creates two settings buttons (on the user menu and on
 * the login menu) that give access to the Revit Plugin settings.
 */
@Injectable()
export class RevitAddInSettingsButtonService {
  private readonly labelText:string;

  private readonly groupLabelText:string;

  constructor(
    private readonly i18n:I18nService,
  ) {
    const onRevitAddInEnvironment = window.navigator.userAgent.search('Revit') > -1;

    if (onRevitAddInEnvironment) {
      this.labelText = i18n.t('js.revit.revit_add_in_settings');
      this.groupLabelText = i18n.t('js.revit.revit_add_in');

      this.addUserMenuItem();
      this.addLoginMenuItem();
    }
  }

  public addUserMenuItem():void {
    const userMenu = document.getElementById('user-menu');

    if (userMenu) {
      const menuItem:HTMLElement = document.createElement('li');
      menuItem.dataset.name = this.labelText;
      menuItem.innerHTML = `
        <a class="op-menu--item-action revit-addin-settings-menu-item ellipsis" title="${this.labelText}" href="#">
          <span class="menu-item--title ellipsis ">${this.labelText}</span>
        </a>
      `;

      menuItem.addEventListener('click', () => this.goToSettings());
      userMenu.appendChild(menuItem);
    }
  }

  public addLoginMenuItem() {
    const loginModal = document.querySelector('#nav-login-content');

    if (loginModal) {
      const loginMenuItem:HTMLElement = document.createElement('div');

      loginMenuItem.dataset.name = this.labelText;
      loginMenuItem.innerHTML = `
        <div class="login-auth-providers">
          <h3 class="login-auth-providers-title">
            <span>
              ${this.groupLabelText}
            </span>
           </h3>
          <div class="login-auth-provider-list revit-add-in-button">
            <div class="auth-provider auth-provider-developer button">
              <span class="auth-provider-name">${this.labelText}</span>
            </div>
          </div>
        </div>
      `;
      loginModal.appendChild(loginMenuItem);

      const settingsButton = loginModal.querySelector('.revit-add-in-button');
      settingsButton?.addEventListener('click', () => this.goToSettings());
    }
  }

  goToSettings() {
    window.RevitBridge.sendMessageToRevit('GoToSettings', '1', '');
  }
}
