import { Injectable, inject } from '@angular/core';
import { type FrameElement } from '@hotwired/turbo';
import { StateService } from '@uirouter/core';

@Injectable({ providedIn: 'root' })
export class SubmenuService {
  protected $state = inject(StateService);


  reloadSubmenu(selectedQueryId:string|null, sidemenuId?:string):void {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
    const menuIdentifier:string|undefined = sidemenuId ?? this.$state.current.data?.sideMenuOptions?.sidemenuId;
    if (!menuIdentifier) { return; }

    const menu = document.getElementById(menuIdentifier) as FrameElement|null;
    const currentSrc = menu?.getAttribute('src');
    if (!currentSrc || !menu) { return; }

    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    const sideMenuOptions = this.$state.$current.data?.sideMenuOptions as { hardReloadOnBaseRoute?:boolean, defaultQuery?:string };
    const frameUrl = new URL(currentSrc, window.location.origin);

    if (selectedQueryId) {
      // Prefer the data attribute on the frame, then fall back to route sideMenuOptions,
      // then default to 'query_id'. Modules with path-based IDs (e.g. calendars/:id)
      // set data-query-param="id" on the frame.
      const queryParam = menu.getAttribute('data-query-param')
        ?? (sideMenuOptions?.defaultQuery ? 'id' : 'query_id');

      frameUrl.search = `?${queryParam}=${selectedQueryId}`;
    }

    const newSrc = frameUrl.href;
    if (menu.getAttribute('src') !== newSrc) {
      menu.setAttribute('src', newSrc);
    } else {
      void menu.reload();
    }
  }
}
