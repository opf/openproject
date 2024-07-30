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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { input, InputState } from '@openproject/reactivestates';
import {
  filter,
  map,
  take,
} from 'rxjs/operators';
import {
  firstValueFrom,
  Observable,
  of,
} from 'rxjs';

interface CacheInput<T> {
  id:string;
  value:T;
}

export abstract class WorkPackageLinkedResourceCache<T> {
  protected cacheDurationInSeconds = 120;

  // Cache activities for the last work package
  // to allow fast switching between work packages without refreshing.
  protected cache:{ id:string|null, state:InputState<CacheInput<T>> } = {
    id: null,
    state: input<CacheInput<T>>(),
  };

  /**
   * Requires the linked resource for the given work package.
   * Caches a single value for subsequent requests for +cacheDurationInSeconds+ seconds.
   *
   * Whenever another work package's linked resource is requested, the cache is replaced.
   *
   * @param {WorkPackageResource} workPackage
   * @returns {Promise<T>}
   */
  public requireAndStream(workPackage:WorkPackageResource, force = false):Observable<T> {
    const id = (workPackage.id as string|number).toString();
    const { state } = this.cache;

    // Clear cache if requesting different resource
    if (force || this.cache.id !== id) {
      state.clear();
    }

    // Return cached value if id matches and value is present
    if (this.isCached(id) && state.value) {
      return of(state.value.value);
    }

    if (!this.isRequested(id)) {
      // Ensure value is loaded only once
      this.cache.id = id;
      this.cache.state.clearAndPutFromPromise(this.load(workPackage).then((value) => ({ value, id })));
    }

    return this
      .cache
      .state
      .values$()
      .pipe(
        filter((cached) => cached && cached.id === id),
        map((cached) => cached.value),
      );
  }

  public require(workPackage:WorkPackageResource, force = false):Promise<T> {
    return firstValueFrom(this.requireAndStream(workPackage, force));
  }

  public clear(workPackageId:string|null) {
    if (this.cache.id === workPackageId) {
      this.cache.state.clear();
    }
  }

  /**
   * Return whether the given work package is cached.
   * @param {string} workPackageId
   * @returns {boolean}
   */
  public isCached(workPackageId:string) {
    const { state } = this.cache;
    return this.cache.id === workPackageId && state.hasValue() && !state.isValueOlderThan(this.cacheDurationInSeconds * 1000);
  }

  /**
   * Return whether the given work package is cached.
   * @param {string} workPackageId
   * @returns {boolean}
   */
  public isRequested(workPackageId:string) {
    const { state } = this.cache;
    return this.cache.id === workPackageId && state.hasActivePromiseRequest();
  }

  /**
   * Load the linked resource and return it as a promise
   * @param {WorkPackageResource} workPackage
   */
  protected abstract load(workPackage:WorkPackageResource):Promise<T>;
}
