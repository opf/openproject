import {Injectable, Injector} from '@angular/core';
import {RevitBridgeService} from "core-app/modules/bim/revit_addin/revit-bridge.service";

@Injectable()
export class RevitAddinSettingsButtonService {
  constructor(readonly injector:Injector,
              readonly revitBridgeService:RevitBridgeService) {
    this.addButton();
  }

  callSettingsPage() {
    this.revitBridgeService.goToSettings();
    return false;
  }

  public addButton():void {
    const menuItem:HTMLElement = document.createElement('li');
    menuItem.dataset.name = "Revit Addin settings";
    menuItem.innerHTML = `
      <a class="revit-addin-settings-menu-item ellipsis" title="Revit Addin settings" href="#">
        <span class="menu-item--title ellipsis ">Revit Addin settings</span>
      </a>
    `;

    const navLoginHtml:string = "<div>yay</div>";

    console.log('loggy', jQuery('#nav-login-content'));

    document.getElementById('user-menu').appendChild(menuItem);

    // jQuery(menuItemHtml)
    //   .appendTo('#user-menu')
    //   .on('click', this.callSettingsPage);

    // jQuery(navLoginHtml)
    //   .attachTo('#nav-login-content')
    //   .on('click', this.callSettingsPage);
  }
}
