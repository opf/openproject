// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {WorkPackageQueryStateService} from './wp-view-base.service';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {Injectable} from '@angular/core';

@Injectable()
export class WorkPackageViewSumService extends WorkPackageQueryStateService<boolean> {

  public constructor(querySpace:IsolatedQuerySpace) {
    super(querySpace);
  }

  public valueFromQuery(query:QueryResource) {
    return !!query.sums;
  }

  public initialize(query:QueryResource) {
    this.pristineState.putValue(!!query.sums);
  }

  public hasChanged(query:QueryResource) {
    return query.sums !== this.isEnabled;
  }

  public applyToQuery(query:QueryResource) {
    query.sums = this.isEnabled;
    return true;
  }

  public toggle() {
    this.updatesState.putValue(!this.current);
  }

  public setEnabled(value:boolean) {
    this.updatesState.putValue(value);
  }

  public get isEnabled() {
    return this.current;
  }

  public get current():boolean {
    return this.lastUpdatedState.getValueOr(false);
  }
}
