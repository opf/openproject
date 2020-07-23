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

import {APIv3GettableResource, APIv3ResourcePath} from "core-app/modules/apiv3/paths/apiv3-resource";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {States} from "core-components/states.service";
import {StateCacheParameters, StateCacheService} from "core-app/modules/apiv3/cache/state-cache.service";
import {Observable} from "rxjs";
import {MultiInputState} from "reactivestates";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";

export abstract class CachableAPIV3Resource<T extends HalResource = HalResource>
  extends APIv3GettableResource<T> {
  @InjectField() states:States;

  readonly cache = this.createCache();

  /**
   * Returns a (potentially cached) observable
   *
   * Accesses or modifies the global store for this resource.
   */
  get():Observable<T> {
    return this.cache.require(this.id.toString());
  }

  /**
   * Returns a freshly loaded value but ensuring the value
   * is also updated in the cache.
   *
   * Accesses or modifies the global store for this resource.
   */
  getFresh():Observable<T> {
    return this.cache.require(this.id.toString(), true);
  }

  /**
   * Perform a request to the HalResourceService with the current path
   */
  protected load():Observable<T> {
    return this
      .halResourceService
      .get<T>(this.path);
  }

  /**
   * touch the cache for the given resource
   */
  protected touch(resource:T):void {
    this
      .cache
      .updateFor(resource);
  }

  /**
   * Returns the cache state to be used for the cached resource
   */
  protected abstract cacheState():MultiInputState<T>;

  /**
   * Provide an optional loadAll handler that loads the entire
   * collection to be put into cache
   */
  protected loadAll():(() => Observable<T[]>)|undefined {
    return undefined;
  }

  /**
   * Creates the cache state instance
   */
  protected createCache():StateCacheService<T> {
    return new StateCacheService(this.cacheStateParameters());
  }

  /**
   * Cache state creation arguments
   */
  protected cacheStateParameters():StateCacheParameters<T> {
    return {
      state: this.cacheState(),
      load: this.load.bind(this),
      loadAll: this.loadAll()
    };
  }

}
