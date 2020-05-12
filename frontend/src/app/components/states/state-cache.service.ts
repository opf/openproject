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

import {InputState, MultiInputState, State} from 'reactivestates';
import {Observable} from "rxjs";
import {auditTime, map, startWith} from "rxjs/operators";

export abstract class StateCacheService<T> {
  private cacheDurationInMs:number;

  constructor(private holdValuesForSeconds:number = 3600) {
    this.cacheDurationInMs = holdValuesForSeconds * 1000;
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
   * Update the value due to application changes.
   *
   * @param id The value's identifier.
   * @param val<T> The value.
   */
  public updateValue(id:string, val:T) {
    this.multiState.get(id).putValue(val);
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
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * @param id The value's identifier.
   * @param force Load the value anyway.
   */
  public require(id:string, force:boolean = false):Promise<T> {
    const state = this.multiState.get(id);

    // Refresh when stale or being forced
    if (this.stale(state) || force) {
      let promise = this.load(id);
      state.clearAndPutFromPromise(promise);
      return promise;
    }

    return state.valuesPromise() as Promise<T>;
  }

  /**
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * Returns an observable to the values stream of the state.
   *
   * @param id The value's identifier.
   * @param force Load the value anyway.
   */
  public requireAndStream(id:string, force:boolean = false):Observable<T> {
    const state = this.multiState.get(id);

    // Refresh when stale or being forced
    if (this.stale(state) || force) {
      state.clear();
      state.putFromPromiseIfPristine(() => this.load(id));
    }

    return state.values$();
  }

  /**
   * Require the states of the given ids to be loaded if they're empty or stale,
   * or all when force is given.
   * @param ids Ids to require
   * @param force Load the values anyway
   * @return {Promise<undefined>} An empty promise to mark when the set of states is filled.
   */
  public requireAll(ids:string[], force:boolean = false):Promise<unknown> {
    let idsToRequest:string[];

    if (force) {
      idsToRequest = ids;
    } else {
      idsToRequest = ids.filter((id:string) => this.stale(this.multiState.get(id)));
    }

    if (idsToRequest.length === 0) {
      return Promise.resolve(undefined);
    }

    return this.loadAll(idsToRequest);
  }

  /**
   * Returns whether the state
   * @param state
   * @return {boolean}
   */
  protected stale(state:InputState<T>):boolean {
    // If there is an active request that is still pending
    if (state.hasActivePromiseRequest()) {
      return false;
    }

    return state.isPristine() || state.isValueOlderThan(this.cacheDurationInMs);
  }

  /**
   * Returns the internal state object
   */
  protected abstract get multiState():MultiInputState<T>;

  /**
   * Load a single value into the cache state.
   * Subclassses need to ensure it gets loaded and resolve or reject the promise
   * @param id The identifier of the value object of type T.
   */
  protected abstract load(id:string):Promise<T>;

  /**
   * Load a set of required values, fill the results into the appropriate states
   * and return a promise when all values are inserted.
   */
  protected abstract loadAll(ids:string[]):Promise<undefined|unknown>;
}
