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

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {input, InputState} from 'reactivestates';
import {take} from 'rxjs/operators';

export abstract class WorkPackageLinkedResourceCache<T> {

  protected cacheDurationInSeconds = 120;

  // Cache activities for the last work package
  // to allow fast switching between work packages without refreshing.
  protected cache:{ id:string|null, state:InputState<T> } = {
    id: null,
    state: input<T>()
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
  public require(workPackage:WorkPackageResource, force:boolean = false):Promise<T> {
    const id = workPackage.id!;
    const state = this.cache.state;

    // Clear cache if requesting different resource
    if (force || this.cache.id !== id) {
      state.clear();
    }

    // Return cached value if id matches and value is present
    if (this.isCached(id)) {
      return Promise.resolve(state.value!);
    }

    // Ensure value is loaded only once
    this.cache.id = id;
    this.cache.state.putFromPromiseIfPristine(() => this.load(workPackage));

    return this.cache.state
      .values$()
      .pipe(take(1))
      .toPromise();
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
    const state = this.cache.state;
    return this.cache.id === workPackageId && state.hasValue() && !state.isValueOlderThan(this.cacheDurationInSeconds * 1000);
  }

  /**
   * Load the linked resource and return it as a promise
   * @param {WorkPackageResource} workPackage
   */
  protected abstract load(workPackage:WorkPackageResource):Promise<T>;
}
