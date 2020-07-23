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
import {forkJoin, NEVER, Observable} from "rxjs";
import {auditTime, map, startWith, tap} from "rxjs/operators";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

export interface StateCacheParameters<T> {
  /**
   * The state that is going to hold the cache values
   */
  state:MultiInputState<T>;

  /**
   * The max cache value in seconds,
   * will default to +holdValuesForSeconds+ constant.
   */
  holdValuesForSeconds?:number;

  /**
   * Load a single value into the cache state.
   * @param id The identifier of the value object of type T.
   * @returns an Observable with either the loaded T, or multiple values to be inserted into state
   */
  load?:(id:string) => Observable<T>;

  /**
   * Load all values to retrieve a single value
   *
   * @returns an Observable with either multiple loaded T values to be inserted into state
   */
  loadAll?:() => Observable<T[]>;
}

export const holdValuesForSeconds = 3600;

export class StateCacheService<T extends HalResource = HalResource> {
  protected cacheDurationInMs:number;
  protected load?:(id:string) => Observable<T>;
  protected loadAll?:() => Observable<T[]>;
  protected multiState:MultiInputState<T>;

  constructor(args:StateCacheParameters<T>) {
    this.multiState = args.state;
    this.cacheDurationInMs = args.holdValuesForSeconds || holdValuesForSeconds;
    this.load = args.load;
    this.loadAll = args.loadAll;

    if (args.load || args.loadAll) {
      throw new Error("Either load or loadAll need to be defined");
    }
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
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * Returns an observable to the values stream of the state.
   *
   * @param id The value's identifier.
   * @param force Load the value anyway.
   */
  public require(id:string, force:boolean = false):Observable<T> {
    const state = this.multiState.get(id);

    // Refresh when stale or being forced
    if (this.stale(state) || force) {
      state.clear();
      return this.loadValueAndUpdate(id);
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
  public requireAll(ids:string[], force:boolean = false):Observable<T[]> {
    let idsToRequest:string[];

    if (force) {
      idsToRequest = ids;
    } else {
      idsToRequest = ids.filter((id:string) => this.stale(this.multiState.get(id)));
    }

    if (idsToRequest.length === 0) {
      return NEVER;
    }

    return this.forkJoinLoad(idsToRequest);
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
   * Loads one or multiple values and inserts them all into the state.
   * @param id
   */
  private loadValueAndUpdate(id:string):Observable<T> {
    if (this.load) {
      return this
        .load(id)
        .pipe(
          tap(val => this.updateValue(id, val))
        );
    }

    return this
      .loadAll!()
      .pipe(
        tap((values:T[]) => values.forEach(val => this.updateValue(val.id!, val))),
        map(values => values.find(val => val.id! === id)!)
      );
  }

  /**
   * Some endpoints do not offer an index endpoint. For this reason,
   * this helper is just going to call +load(id)+ on all requested ids
   * individually and forkjoin the results.
   *
   * Other endpoints use the load() method to load all results regardless
   * of ID for performance reasons to avoid individual requests.
   */
  private forkJoinLoad(ids:string[]):Observable<T[]> {
    if (this.loadAll) {
      return this
        .loadAll()
        .pipe(
          map(values => values.filter(val => ids.includes(val.id!)))
        );
    }

    let observables = ids.map(id => this.loadValueAndUpdate(id));
    return forkJoin(observables);
  }
}

