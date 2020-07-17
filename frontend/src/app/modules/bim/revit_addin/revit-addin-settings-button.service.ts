import {Injectable, Injector} from '@angular/core';
import {RevitBridgeService} from "core-app/modules/bim/revit_addin/revit-bridge.service";

/*
 * This service conditionally creates two settings buttons (on the user menu and on
 * the login menu) that give access to the Revit Plugin settings.
 */
@Injectable()
export class RevitAddinSettingsButtonService {
  constructor(readonly injector:Injector) {
    const onRevitAddinEnvironment = window.navigator.userAgent.search('Revit') > -1;

    if (onRevitAddinEnvironment) {
      this.addUserMenuItem();
      this.addLoginMenuItem();
    }
  }

  public addUserMenuItem():void {
    const userMenu = document.getElementById('user-menu');

    if (userMenu) {
      const menuItem:HTMLElement = document.createElement('li');
      menuItem.dataset.name = 'Revit Addin settings';
      menuItem.innerHTML = `
        <a class="revit-addin-settings-menu-item ellipsis" title="Revit Addin settings" href="#">
          <span class="menu-item--title ellipsis ">Revit Addin settings</span>
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
      loginMenuItem.dataset.name = 'Revit Addin settings';
      loginMenuItem.innerHTML = `
        <div class="login-auth-providers">
          <h3 class="login-auth-providers-title">
            <span>
             Revit Addin
            </span>
           </h3>
          <div class="login-auth-provider-list revit-addin-button">
            <div class="auth-provider auth-provider-developer button">
              <span class="auth-provider-name">Go to Revit Addin settings</span>
            </div>
          </div>
        </div>
      `;
      loginModal.appendChild(loginMenuItem);

      const settingsButton = loginModal.querySelector('.revit-addin-button');

      settingsButton!.addEventListener('click', () => this.goToSettings());
    }
  }

  goToSettings() {
    window.RevitBridge.sendMessageToRevit('GoToSettings', '1', '');
  }
}
