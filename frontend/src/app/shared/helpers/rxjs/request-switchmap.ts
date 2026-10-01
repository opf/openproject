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

import { Observable, Subject } from 'rxjs';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { switchMap, takeUntil } from 'rxjs/operators';

export type RequestSwitchmapHandler<T, R> = (input:T) => Observable<R>;

export class RequestSwitchmap<T, R = HalResource> {
  /** Input request state */
  private requests = new Subject<T>();

  /** Output switchmap observable */
  private responses$ = this.requests
    .pipe(
      // Stream the request, switchMap will result in previous requests to be cancelled
      switchMap(this.handler),
    );

  /**
   *
   * @param handler switch map handler function to output a response observable
   */
  constructor(readonly handler:RequestSwitchmapHandler<T, R>) {
  }

  /**
   * Append a new request for the given request value and pass
   * that to the switchmap handler
   * @param newValue
   */
  public request(newValue:T) {
    this.requests.next(newValue);
  }

  /**
   * Observe the switched response
   */
  public observe(until:Observable<unknown>) {
    return this
      .responses$
      .pipe(
        takeUntil(until),
      );
  }
}
