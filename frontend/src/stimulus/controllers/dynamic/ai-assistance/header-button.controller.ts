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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Controller } from '@hotwired/stimulus';
import type { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import type { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { useAngularServices, type ServiceKey } from 'core-stimulus/mixins/use-angular-services';
import { WORK_PACKAGE_UPDATED_EVENT } from 'core-stimulus/helpers/my-work-entry-menus';

// The AI Assistance button in the app header. It shows the menu for the work package that is
// open (full view, or the split view of a list, a board or a calendar), and hides elsewhere.
// The header is not rendered again on Turbo frame visits, so it follows the URL: through the
// Navigation API where the browser has it (it also reports pushState), else through Turbo events.
export default class extends Controller<HTMLElement> {
  static targets = ['frame'];

  static values = { menuUrl: String };

  static services:ServiceKey[] = ['apiV3Service', 'halEvents'];

  declare readonly frameTarget:HTMLElement;
  declare readonly menuUrlValue:string;
  declare apiV3Service:ApiV3Service;
  declare halEvents:HalEventsService;

  initialize():void {
    useAngularServices(this);
  }

  connect():void {
    window.navigation?.addEventListener('currententrychange', this.update);
    document.addEventListener('turbo:load', this.update);
    document.addEventListener('turbo:frame-load', this.frameLoaded);
    window.addEventListener('popstate', this.update);
    document.addEventListener(WORK_PACKAGE_UPDATED_EVENT, this.refresh);
    this.update();
  }

  disconnect():void {
    window.navigation?.removeEventListener('currententrychange', this.update);
    document.removeEventListener('turbo:load', this.update);
    document.removeEventListener('turbo:frame-load', this.frameLoaded);
    window.removeEventListener('popstate', this.update);
    document.removeEventListener(WORK_PACKAGE_UPDATED_EVENT, this.refresh);
  }

  // A split view loads in a frame. The menu's own frame loads too, and must not trigger a reload.
  private frameLoaded = (event:Event):void => {
    if (event.target !== this.frameTarget) {
      this.update();
    }
  };

  private update = ():void => {
    const id = workPackageIdFrom(window.location.pathname);
    this.element.hidden = !id;
    if (!id) {
      this.frameTarget.removeAttribute('src');
      this.frameTarget.innerHTML = '';
      return;
    }

    // Turbo stores the src as an absolute URL.
    const src = new URL(this.menuUrlValue.replace('__ID__', encodeURIComponent(id)), window.location.origin).href;
    if (this.frameTarget.getAttribute('src') !== src) {
      this.frameTarget.setAttribute('src', src);
    }
  };

  // After a proposal changed the work package, reload it, so the next inline edit does not conflict.
  private refresh = (event:Event):void => {
    const id = (event as CustomEvent<{ work_package_id?:number|string }>).detail?.work_package_id;
    if (!id) {
      return;
    }

    void this.apiV3Service
      .work_packages
      .id(String(id))
      .refresh()
      .then((workPackage) => this.halEvents.push(workPackage, { eventType: 'updated' }));
  };
}

const ID = '(\\d+|[A-Za-z][A-Za-z0-9_]*-\\d+)';
const SPLIT_VIEW = new RegExp(`/details/${ID}(?:/|$)`);
const FULL_VIEW = new RegExp(`/work_packages/${ID}(?:/|$)`);

// The id of the open work package: a split view first, then the full view.
export function workPackageIdFrom(path:string):string|null {
  return SPLIT_VIEW.exec(path)?.[1] ?? FULL_VIEW.exec(path)?.[1] ?? null;
}
