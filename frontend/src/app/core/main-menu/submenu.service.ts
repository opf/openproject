import { Injectable } from '@angular/core';
import { TurboElement } from 'core-typings/turbo';
import { StateService } from '@uirouter/core';

@Injectable({ providedIn: 'root' })
export class SubmenuService {
  constructor(protected $state:StateService) {}

  reloadSubmenu():void {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
    const menuIdentifier:string|undefined = this.$state.current.data.sideMenuOptions?.sidemenuId;

    if (menuIdentifier) {
      const menu = (document.getElementById(menuIdentifier) as HTMLElement&TurboElement);
      const currentSrc = menu.getAttribute('src');

      if (currentSrc && menu) {
        const frameUrl = new URL(currentSrc);

        // Override the frame src to enforce a reload
        menu.setAttribute('src', frameUrl.href);
      }
    }
  }
}
