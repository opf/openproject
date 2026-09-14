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
  filter,
  map,
  withLatestFrom,
} from 'rxjs/operators';
import { Observable } from 'rxjs';

/**
 * Filter emissions from the source observable
 * using values from another observable.
 *
 * Applies the given filter function and maps to the original observable.
 *
 * @param other$ Other observable to observe values
 * @param filterFn Filter to apply to values of other$
 */
export function filterObservable<T, V>(
  other$:Observable<V>,
  filterFn:(val:V) => boolean,
):(source$:Observable<T>) => Observable<T> {
  return (source$) => source$
    .pipe(
      withLatestFrom(other$),
      filter(([, val]) => filterFn(val)),
      map(([source]) => source),
    );
}
