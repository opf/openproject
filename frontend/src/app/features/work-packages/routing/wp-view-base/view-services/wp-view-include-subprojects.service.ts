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

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { Injectable } from '@angular/core';
import { WorkPackageQueryStateService } from './wp-view-base.service';

@Injectable()
export class WorkPackageViewIncludeSubprojectsService extends WorkPackageQueryStateService<boolean> {
  public constructor(
    readonly states:States,
    readonly querySpace:IsolatedQuerySpace,
  ) {
    super(querySpace);
  }

  public hasChanged(query:QueryResource):boolean {
    return this.current !== query.includeSubprojects;
  }

  valueFromQuery(query:QueryResource):boolean {
    return query.includeSubprojects || false;
  }

  public applyToQuery(query:QueryResource):boolean {
    const { current } = this;
    query.includeSubprojects = current; // eslint-disable-line no-param-reassign

    return true;
  }

  public get current():boolean {
    return this.lastUpdatedState.getValueOr(false);
  }

  public setIncludeSubprojects(include:boolean):void {
    this.update(include);
  }
}
