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

import { ApiV3GettableResource, ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { States } from 'core-app/core/states/states.service';
import { HasId, StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { Observable } from 'rxjs';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { tap } from 'rxjs/operators';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export abstract class ApiV3Collection<
  T extends HasId = HalResource,
  V extends ApiV3GettableResource<T> = ApiV3GettableResource<T>,
  X extends StateCacheService<T> = StateCacheService<T>,
  >
  extends ApiV3ResourceCollection<T, V> {
  @InjectField() states:States;

  readonly cache:X = this.createCache();

  /**
   * Observe all value changes of the cache
   */
  public observeAll():Observable<T[]> {
    return this.cache.observeAll();
  }

  /**
   * Inserts a collection or single response to cache as an rxjs tap function
   */
  protected cacheResponse<R>():(source:Observable<R>) => Observable<R> {
    return (source$) => source$.pipe(
      tap(
        (response:R) => {
          if (response instanceof CollectionResource) {
            response.elements?.forEach(this.touch.bind(this));
          } else if (response instanceof HalResource) {
            this.touch(response as any);
          }
        },
      ),
    );
  }

  /**
   * Update a single resource
   */
  protected touch(resource:T):void {
    this.cache.updateFor(resource);
  }

  /**
   * Creates the cache state instance
   */
  protected abstract createCache():X;
}
