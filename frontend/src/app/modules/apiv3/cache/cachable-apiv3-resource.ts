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

import { APIv3GettableResource } from "core-app/modules/apiv3/paths/apiv3-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { States } from "core-components/states.service";
import { HasId, StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";
import { concat, from, merge, Observable, of } from "rxjs";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { mapTo, publish, share, shareReplay, switchMap, take, tap } from "rxjs/operators";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";

export abstract class CachableAPIV3Resource<T extends HasId = HalResource>
  extends APIv3GettableResource<T> {
  @InjectField() states:States;
  @InjectField() schemaCache:SchemaCacheService;

  readonly cache = this.createCache();

  /**
   * Require the value to be loaded either when forced or the value is stale
   * according to the cache interval specified for this service.
   *
   * Returns an observable to the values stream of the state.
   *
   * @param force Load the value anyway.
   */
  public requireAndStream(force = false):Observable<T> {
    const id = this.id.toString();

    // Refresh when stale or being forced
    if (this.cache.stale(id) || force) {
      const observable = this
        .load()
        .pipe(
          take(1),
          shareReplay(1)
        );

      this.cache.clearAndLoad(
        id,
        observable
      );

      // Return concat of the loading observable
      // for error handling and the like,
      // but then continue with the streamed cache
      return concat<T>(
        observable,
        this.cache.state(id).values$()
      );
    }

    return this.cache.state(id).values$();
  }


  /**
   * Observe the values of this resource,
   * but do not request it actively.
   */
  public observe():Observable<T> {
    return this
      .cache
      .observe(this.id.toString());
  }


  /**
   * Returns a (potentially cached) observable.
   *
   * Only observes one value.
   *
   * Accesses or modifies the global store for this resource.
   */
  get():Observable<T> {
    return this
      .requireAndStream(false)
      .pipe(
        take(1)
      );
  }

  /**
   * Returns a freshly loaded value but ensuring the value
   * is also updated in the cache.
   *
   * Only observes one value.
   *
   * Accesses or modifies the global store for this resource.
   */
  refresh():Promise<T> {
    return this
      .requireAndStream(true)
      .pipe(
        take(1),
      )
      // Use a promise to ensure this fires
      // even if caller isn't subscribing.
      .toPromise();
  }

  /**
   * Perform a request to the HalResourceService with the current path
   */
  protected load():Observable<T> {
    return this
      .halResourceService
      .get(this.path)
      .pipe(
        switchMap((resource) => {
          if (resource.$links.schema) {
            return this.schemaCache
              .requireAndStream(resource.$links.schema.href)
              .pipe(
                take(1),
                mapTo(resource),
              );
          } else {
            return of(resource);
          }
        })
      ) as any; // T does not extend HalResource for virtual endpoints such as board, thus we need to cast here
  }

  /**
   * Update a single resource
   */
  protected touch(resource:T):void {
    this.cache.updateFor(resource);
  }

  /**
   * Inserts a collection response to cache as an rxjs tap function
   */
  protected cacheResponse():(source:Observable<T>) => Observable<T> {
    return (source$:Observable<T>) => {
      return source$.pipe(
        tap(
          (resource:T) => this.touch(resource)
        )
      );
    };
  }

  /**
   * Creates the cache state instance
   */
  protected abstract createCache():StateCacheService<T>;
}
