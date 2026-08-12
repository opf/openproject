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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

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
