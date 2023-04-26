// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import { Injectable } from '@angular/core';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { States } from 'core-app/core/states/states.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageQueryStateService } from './wp-view-base.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

export const DEFAULT_TIMESTAMP = 'PT0S';

@Injectable()
export class WorkPackageViewBaselineService extends WorkPackageQueryStateService<string[]> {
  constructor(
    protected readonly states:States,
    protected readonly querySpace:IsolatedQuerySpace,
    protected readonly pathHelper:PathHelperService,
    protected readonly configurationService:ConfigurationService,
  ) {
    super(querySpace);
  }

  public isActive():boolean {
    if (!this.configurationService.activeFeatureFlags.includes('showChanges')) {
      return false;
    }

    return this.current.length >= 1 && this.current[0] !== DEFAULT_TIMESTAMP;
  }

  public valueFromQuery(query:QueryResource):string[] {
    return query.timestamps;
  }

  public hasChanged(query:QueryResource) {
    return !_.isEqual(query.timestamps, this.current);
  }

  public applyToQuery(query:QueryResource):boolean {
    query.timestamps = [...this.current];

    return true;
  }

  public get current():string[] {
    return this.lastUpdatedState.getValueOr([DEFAULT_TIMESTAMP]);
  }
}
