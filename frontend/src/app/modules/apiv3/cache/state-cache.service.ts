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

import {MultiInputState, State} from 'reactivestates';
import {Observable} from "rxjs";
import {auditTime, map, startWith} from "rxjs/operators";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

export interface HasId {
  id:string|null;
}

export class StateCacheService<T extends HasId = HalResource> {
  protected cacheDurationInMs:number;
  protected load?:(id:string) => Observable<T>;
  protected loadAll?:() => Observable<T[]>;
  protected multiState:MultiInputState<T>;

  constructor(state:MultiInputState<T>, holdValuesForSeconds:number = 3600) {
    this.multiState = state;
    this.cacheDurationInMs = holdValuesForSeconds;
  }

  public state(id:string):State<T> {
    return this.multiState.get(id);
  }

  /**
   * Touch the current state to fire subscribers.
   */
  public touch(id:string):void {
    const state = this.multiState.get(id);
    state.putValue(state.value, 'Touching the state');
  }

  /**
   * Get the current value
   */
  public current(id:string, fallback?:T):T|undefined {
    return this.state(id).getValueOr(fallback);
  }

  /**
   * Sets a promise to the state
   */
  public clearAndLoad(id:string, loader:Observable<T>):Observable<T> {
    this
      .multiState.get(id)
      .clearAndPutFromPromise(loader.toPromise());

    return loader;
  }

  /**
   * Update the value due to application changes.
   *
   * @param id The value's identifier.
   * @param val<T> The value.
   */
  public updateValue(id:string, val:T) {
    this.multiState.get(id).putValue(val);
  }

  /**
   * Update the value due to application changes.
   *
   * @param id The value's identifier.
   * @param val<T> The value.
   */
  public updateFor(resource:T) {
    this
      .multiState
      .get(resource.id!)
      .putValue(resource);
  }


  /**
   * Observe the value of the given id
   */
  public observe(id:string):Observable<T> {
    return this.state(id).values$();
  }

  /**
   * Observe the changes of the given id
   */
  public changes$(id:string):Observable<T|undefined> {
    return this.state(id).changes$();
  }

  /**
   * Observe the entire set of loaded results
   */
  public observeAll():Observable<T[]> {
    return this.multiState
      .observeChange()
      .pipe(
        startWith([]),
        auditTime(250),
        map(() => {
          let mapped:T[] = [];
          _.each(this.multiState.getValueOr({}), (state:State<T>) => {
            if (state.value) {
              mapped.push(state.value);
            }
          });

          return mapped;
        })
      );
  }

  /**
   * Clear a set of cached states.
   * @param ids
   */
  public clearSome(...ids:string[]) {
    ids.forEach(id => this.multiState.get(id).clear());
  }



  /**
   * Returns whether the state
   * @param state
   * @return {boolean}
   */
  public stale(id:string):boolean {
    const state = this.multiState.get(id);

    // If there is an active request that is still pending
    if (state.hasActivePromiseRequest()) {
      return false;
    }

    return state.isPristine() || state.isValueOlderThan(this.cacheDurationInMs);
  }
}

