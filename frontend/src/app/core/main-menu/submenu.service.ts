import { Injectable } from '@angular/core';
import { TurboElement } from 'core-typings/turbo';
import { StateService } from '@uirouter/core';

@Injectable({ providedIn: 'root' })
export class SubmenuService {
  constructor(protected $state:StateService) {}

  reloadSubmenu(selectedQueryId:string|null):void {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
    const menuIdentifier:string|undefined = this.$state.current.data.sideMenuOptions?.sidemenuId;

    if (menuIdentifier) {
      const menu = (document.getElementById(menuIdentifier) as HTMLElement&TurboElement);
      // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
      const sideMenuOptions = this.$state.$current.data?.sideMenuOptions as { hardReloadOnBaseRoute?:boolean, defaultQuery?:string };
      const currentSrc = menu.getAttribute('src');

      if (currentSrc && menu) {
        const frameUrl = new URL(currentSrc);
        const defaultQuery = sideMenuOptions.defaultQuery;

        if (selectedQueryId) {
          // If there is a default query passed in the route definition, it means that id passed as argument and not as parameter,
          // e.g. calendars/:id, team_planner/:id, ...
          // Otherwise, we will just replace the params
          if (defaultQuery) {
            frameUrl.search = `?id=${selectedQueryId}`;
          } else {
            frameUrl.search = `?query_id=${selectedQueryId}`;
          }
        }

        // Override the frame src to enforce a reload
        menu.setAttribute('src', frameUrl.href);
      }
    }
  }
}
