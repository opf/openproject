//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
//++

import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { combine, deriveRaw, input, State } from 'reactivestates';
import { map, mapTo, take } from 'rxjs/operators';
import { merge, Observable } from 'rxjs';
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { QuerySchemaResource } from 'core-app/modules/hal/resources/query-schema-resource';
import { WorkPackageCollectionResource } from 'core-app/modules/hal/resources/wp-collection-resource';
import { Injectable } from "@angular/core";

@Injectable()
export abstract class WorkPackageViewBaseService<T> {
  /** Internal state to push non-persisted updates */
  protected updatesState = input<T>();

  /** Internal pristine state filled during +initialize+ only */
  protected pristineState = input<T>();

  constructor(protected readonly querySpace:IsolatedQuerySpace) {
  }

  /**
   * Get the state value from the current query.
   *
   * @param {QueryResource} query
   * @returns {T} Instance of the state value for this type.
   */
  public abstract valueFromQuery(query:QueryResource, results:WorkPackageCollectionResource):T|undefined;

  /**
   * Initialize this table state from the given query resource,
   * and possibly the associated schema.
   *
   * @param {QueryResource} query
   * @param {QuerySchemaResource} schema
   */
  public initialize(query:QueryResource, results:WorkPackageCollectionResource, schema?:QuerySchemaResource) {
    const initial = this.valueFromQuery(query, results)!;
    this.pristineState.putValue(initial);
  }

  public update(value:T) {
    this.updatesState.putValue(value);
  }

  public clear(reason:string) {
    this.pristineState.clear(reason);
    this.updatesState.clear(reason);
  }

  /**
   * Get the combined pristine and update value changes
   * @param unsubscribe
   */
  public live$():Observable<T> {
    return merge(
      this.pristineState.values$(),
      this.updatesState.values$(),
    );
  }

  /**
   * Get pristine upstream changes
   *
   * @param unsubscribe
   */
  public pristine$():Observable<T> {
    return this
      .pristineState
      .values$();
  }

  /**
   * Get only the local update changes
   *
   * @param unsubscribe
   */
  public updates$():Observable<T> {
    return this
      .updatesState
      .values$();
  }

  /**
   * Get only the local update changes
   *
   * @param unsubscribe
   */
  public changes$():Observable<unknown> {
    return this
      .updatesState
      .changes$();
  }

  public onReady() {
    return this
      .pristineState
      .values$()
      .pipe(
        take(1),
        mapTo(null)
      )
      .toPromise();
  }

  /** Get the last updated value from either pristine or update state */
  protected get lastUpdatedState():State<T> {
    const combinedRaw = combine(this.pristineState, this.updatesState);

    return deriveRaw(combinedRaw,
      ($) => $
        .pipe(
          map(([pristine, current]) => {
            if (current === undefined) {
              return pristine;
            }
            return current;
          })
        )
    );
  }

  /**
   * Helper to set the value of the current state
   * @param val
   */
  protected set current(val:T|undefined) {
    if (val) {
      this.updatesState.putValue(val);
    } else {
      this.updatesState.clear();
    }
  }

  /**
   * Get the value of the current state, if any.
   */
  protected get current():T|undefined {
    return this.lastUpdatedState.value;
  }
}

@Injectable()
export abstract class WorkPackageQueryStateService<T> extends WorkPackageViewBaseService<T> {
  /**
   * Check whether the state value does not match the query resource's value.
   * @param query The current query resource
   */
  abstract hasChanged(query:QueryResource):boolean;

  /**
   * Apply the current state value to query
   *
   * @return Whether the query should be visibly updated.
   */
  abstract applyToQuery(query:QueryResource):boolean;
}
