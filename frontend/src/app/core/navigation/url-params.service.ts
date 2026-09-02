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
import { Observable } from 'rxjs';
import { map, shareReplay, startWith } from 'rxjs/operators';
import { NavigationService } from 'core-app/core/navigation/navigation.service';

@Injectable({ providedIn: 'root' })
export class UrlParamsService {
  private navigation = inject(NavigationService);


  public get(key:string):string|null {
    return this.searchParams.get(key);
  }

  public pathMatching(key:RegExp, url = window.location.pathname):string|null {
    return url.match(key)?.[1] ?? null;
  }

  /**
   * The current list's base path (work packages, gantt, boards, calendars, ...),
   * stripped of any already-open details/:id(/:tab) or create_new suffix. Used to
   * build the next details/create link relative to whichever list is currently rendering.
   *
   * Also strips a work_packages/gantt full-view's own :id(/:tab) suffix, so the button
   * still resolves to the list's create path when clicked from a full work package view.
   */
  public basePathWithoutDetails(url = window.location.pathname):string {
    return url
      .replace(/\/details\/.*$/, '')
      .replace(/\/create_new$/, '')
      .replace(/\/(work_packages|gantt)\/[^/]+(\/[^/]+)?$/, '/$1');
  }

  /**
   * The path to open the split-create form at, for whichever list is currently
   * rendering. Work packages and gantt keep their pre-existing /create_new path;
   * every other satellite (calendar, boards, team planner, bim) uses details/new.
   */
  public splitCreatePath(url = window.location.pathname):string {
    const basePath = this.basePathWithoutDetails(url);
    return /\/(work_packages|gantt)$/.test(basePath) ? `${basePath}/create_new` : `${basePath}/details/new`;
  }

  /** Raw URL-changed signal, for callers that need to react to more than one pattern at once. */
  public get changed$():Observable<string> {
    return this.navigation.urlChanged$;
  }

  public pathMatching$(key:RegExp):Observable<string|null> {
    return this
      .navigation
      .urlChanged$
      .pipe(
        startWith(document.location.href),
        map((url) => this.pathMatching(key, url)),
        shareReplay(1),
      );
  }

  public has(key:string):boolean {
    return this.searchParams.has(key);
  }

  private get searchParams():URLSearchParams {
    return new URLSearchParams(window.location.search);
  }
}
