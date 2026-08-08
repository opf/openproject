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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  map,
  mergeMap,
} from 'rxjs/operators';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import {
  forkJoin,
  Observable,
  of,
} from 'rxjs';
import { ApiV3PaginationParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

/**
 * The API will resolve pageSize=-1 to the maximum value
 * we can request in one call. This is configurable under administration.
 */
export const MAGIC_PAGE_NUMBER = -1;

export const MAGIC_FILTER_AUTOCOMPLETE_PAGE_SIZE = 100;

/**
 * Right now, we still support HAL-class based collections as well as interface-based responses.
 */
type ApiV3CollectionType<T> = CollectionResource<T>|IHALCollection<T>;

/**
 * Extract the elements of either a HAL class or an interface
 */
function extractCollectionElements<T>(collection:ApiV3CollectionType<T>):T[] {
  // Some API endpoints return an undefined _embedded.elements
  // so we ensure we return an array at all times.
  if (collection instanceof HalResource) {
    return collection.elements || [];
  }

  return collection._embedded?.elements || [];
}

/**
 * Get ALL pages of a potentially paginated APIv3 request, returning an array of collections
 *
 * @param request The requesting callback to request specific pages
 * @param pageSize The pageSize parameter to request, defaults to -1 (the maximum magic page number)
 * @return an array of HAL collections
 */
export function getPaginatedCollections<T, C extends ApiV3CollectionType<T>>(
  request:(params:ApiV3PaginationParameters) => Observable<C>,
  pageSize = MAGIC_PAGE_NUMBER,
):Observable<ApiV3CollectionType<T>[]> {
  return request({ pageSize, offset: 1 })
    .pipe(
      mergeMap((collection:C) => {
        const resolvedSize = collection.pageSize;

        if (collection.total > collection.count) {
          const remaining = collection.total - collection.count;
          const pagesRemaining = Math.ceil(remaining / resolvedSize);
          const calls = new Array(pagesRemaining)
            .fill(null)
            .map((_, i) => request({ pageSize: resolvedSize, offset: i + 2 }));

          // Branch out and fetch all remaining pages in parallel.
          // Afterwards, merge the resulting list
          return forkJoin(...calls)
            .pipe(
              map((results:C[]) => [collection, ...results]),
            );
        }

        // The current page is the only page, return the results.
        return of([collection]);
      }),
    );
}

/**
 * Get ALL pages of a potentially paginated APIv3 request, returning all concatenated elements.
 *
 * @param request The requesting callback to request specific pages
 * @param pageSize The pageSize parameter to request, defaults to -1 (the maximum magic page number)
 * @return an array of plain HAL resources
 */
export function getPaginatedResults<T>(
  request:(params:ApiV3PaginationParameters) => Observable<ApiV3CollectionType<T>>,
  pageSize = MAGIC_PAGE_NUMBER,
):Observable<T[]> {
  return getPaginatedCollections(request, pageSize)
    .pipe(
      map(
        (results:ApiV3CollectionType<T>[]) => results.reduce(
          (acc, next) => acc.concat(extractCollectionElements(next)),
          [] as T[],
        ),
      ),
    );
}
