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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, Injector, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Injectable()
export class GlobalSearchService {
  protected I18n = inject(I18nService);
  protected injector = inject(Injector);
  protected PathHelper = inject(PathHelperService);
  protected currentProjectService = inject(CurrentProjectService);


  public submitSearch(query:string, scope:string):void {
    const path = this.searchPath(scope);
    const params = this.searchQueryParams(query, scope);
    window.location.href = `${path}?${params}`;
  }

  public searchPath(scope:string) {
    let searchPath:string = this.PathHelper.staticBase;
    if (this.currentProjectService.path && scope !== 'all') {
      searchPath = this.currentProjectService.path;
    }
    return `${searchPath}/search`;
  }

  private searchQueryParams(query:string, scope:string):string {
    const params = new URLSearchParams(window.location.search);
    params.set('q', query);
    params.set('scope', scope);

    // Filter work packages by default
    if (!params.get('filter')) {
      params.set('filter', 'work_packages');
    }

    return params.toString();
  }
}
