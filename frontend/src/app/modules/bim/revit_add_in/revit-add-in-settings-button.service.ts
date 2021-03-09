import { Injectable, Injector } from '@angular/core';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";

/*
 * This service conditionally creates two settings buttons (on the user menu and on
 * the login menu) that give access to the Revit Plugin settings.
 */
@Injectable()
export class RevitAddInSettingsButtonService {
  private readonly labelText:string;
  private readonly groupLabelText:string;

  constructor(readonly injector:Injector,
              readonly i18n:I18nService) {
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
        <a class="revit-addin-settings-menu-item ellipsis" title="${this.labelText}" href="#">
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

      settingsButton!.addEventListener('click', () => this.goToSettings());
    }
  }

  goToSettings() {
    window.RevitBridge.sendMessageToRevit('GoToSettings', '1', '');
  }
}
