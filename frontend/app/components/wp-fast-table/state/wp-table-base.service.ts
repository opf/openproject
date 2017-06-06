// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {InputState, State} from "reactivestates";
import {States} from "../../states.service";
import {WorkPackageTableBaseState} from "../wp-table-base";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {Observable} from 'rxjs';
import {QueryResource} from '../../api/api-v3/hal-resources/query-resource.service';

export type TableStateStates =
  'columns' |
  'groupBy' |
  'filters' |
  'sum' |
  'sortBy' |
  'timelineVisible' |
  'relationColumns' |
  'pagination';

export abstract class WorkPackageTableBaseService {
  protected abstract stateName:TableStateStates;

  constructor(protected states:States) {
  }

  public get state():InputState<any> {
    return this.states.table[this.stateName];
  }

  public clear(reason:string) {
    this.state.clear(reason);
  }

  public observeOnScope(scope:ng.IScope) {
    return scopedObservable(scope, this.state.values$());
  }

  public observeUntil(unsubscribe:Observable<any>) {
    return this.state.values$().takeUntil(unsubscribe);
  }

  public onReady(scope:ng.IScope) {
    return scopedObservable(scope, this.state.values$()).take(1).mapTo(null).toPromise();
  }
}

export interface WorkPackageQueryStateService {
  /**
   * Check whether the state value does not match the query resource's value.
   * @param query The current query resource
   */
  hasChanged(query:QueryResource):boolean;

  /**
   * Apply the current state value to query
   *
   * @return Whether the query should be visibly updated.
   */
  applyToQuery(query:QueryResource):boolean;

  state:State<any>;
}
