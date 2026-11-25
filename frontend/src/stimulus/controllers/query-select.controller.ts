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
import * as Turbo from '@hotwired/turbo';
import { FrameElement } from '@hotwired/turbo';

/**
 * Handles client-side navigation for query links in Angular-based sidebar menus.
 *
 * Instead of triggering a full page reload, this controller:
 * 1. Updates the browser URL using Turbo's history API
 * 2. Angular's NavigationService detects the URL change and reloads the query
 * 3. Reloads the sidebar menu frame to update the selected state
 *
 * Works with both:
 * - Query param based URLs: /work_packages?query_id=X, /gantt?query_id=X
 * - Path based URLs: /calendars/:id, /team_planners/:id, /boards/:id
 *
 * Wire it on the submenu container with `data-controller="query-select"`
 * and on links with `data-action="click->query-select#navigate"`.
 *
 * Set `data-query-select-frame-id-value` to specify the turbo frame ID to reload.
 */
export default class QuerySelectController extends Controller {
  static values = {
    frameId: String,
  };

  declare frameIdValue:string;

  navigate(event:Event):void {
    const link = event.currentTarget as HTMLAnchorElement;
    const href = link.getAttribute('href');

    if (!href) return;

    const targetUrl = new URL(href, window.location.origin);
    const currentPath = window.location.pathname;

    // Check if this is a same-module navigation (same base path)
    if (!this.isSameModule(currentPath, targetUrl.pathname)) {
      // Let the browser handle external navigation normally
      return;
    }

    event.preventDefault();

    // Update the URL using Turbo's history API
    Turbo.session.history.push(targetUrl);

    // Reload the sidemenu frame to update selection state
    this.reloadSidemenu(targetUrl);
  }

  private isSameModule(currentPath:string, targetPath:string):boolean {
    // Strip details/create_new suffixes and trailing IDs for path-based modules
    const currentBase = this.getModuleBasePath(currentPath);
    const targetBase = this.getModuleBasePath(targetPath);
    return currentBase === targetBase;
  }

  private getModuleBasePath(path:string):string {
    // Remove details/:id/:tab or create_new suffixes
    let basePath = path.replace(/\/(details|create_new)(\/.*)?$/, '');

    // For path-based modules (calendars, team_planners, boards), strip the trailing ID
    // e.g., /projects/foo/calendars/123 -> /projects/foo/calendars
    // But keep query-param based paths intact (work_packages, gantt, bcf)
    const pathBasedModules = /\/(calendars|team_planners|work_package_boards)(\/\d+)?$/;
    basePath = basePath.replace(pathBasedModules, '/$1');

    return basePath;
  }

  private reloadSidemenu(url:URL):void {
    if (!this.frameIdValue) return;

    const frame = document.getElementById(this.frameIdValue) as FrameElement | null;
    if (!frame) return;

    const currentSrc = frame.getAttribute('src');
    if (!currentSrc) return;

    const frameUrl = new URL(currentSrc, window.location.origin);

    // Update the frame URL with new query params from the target URL
    frameUrl.search = url.search;

    const newSrc = frameUrl.href;
    if (frame.getAttribute('src') !== newSrc) {
      frame.setAttribute('src', newSrc);
    } else {
      void frame.reload();
    }
  }
}
