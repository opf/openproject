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
  concat, Observable, of, Subject,
} from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  filter,
  shareReplay,
  switchMap,
  takeUntil,
  tap,
} from 'rxjs/operators';
import { RequestSwitchmapHandler } from 'core-app/shared/helpers/rxjs/request-switchmap';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

export type RequestErrorHandler = (error:unknown) => void;

export function errorNotificationHandler(service:HalResourceNotificationService):RequestErrorHandler {
  return (error:unknown) => service.handleRawError(error);
}

export class DebouncedRequestSwitchmap<T, R = HalResource> {
  /** Input request state */
  public input$ = new Subject<T>();

  /** Output results observable */
  public output$:Observable<R[]>;

  /** Loading flag */
  public loading$ = new Subject<boolean>();

  /** Whether results were returned */
  public lastResult:R[] = [];

  /** Last requested value */
  public lastRequestedValue:T|undefined;

  /**
   * @param handler switch map handler function to output a response observable
   * @param debounceTime {number} Time to debounce in ms.
   * @param preFilterNull {boolean} Whether to exclude null and undefined searches
   * @param emptyValue {R} The empty fall back value before first response or on errors
   */
  constructor(
    readonly requestHandler:RequestSwitchmapHandler<T, R[]>,
    readonly errorHandler:RequestErrorHandler,
    readonly preFilterNull = false,
    readonly debounceMs = 250,
  ) {
    /** Output switchmap observable */
    this.output$ = concat(
      of([]),
      this.input$.pipe(
        filter((val) => !preFilterNull || (val !== undefined && val !== null)),
        distinctUntilChanged(),
        debounceTime(debounceMs),
        tap((val:T) => {
          this.lastRequestedValue = val;
          this.lastResult = [];
          this.loading$.next(true);
        }),
        switchMap((term) => this.requestHandler(term)
          .pipe(
            catchError((error) => {
              this.errorHandler(error);
              return of([]);
            }),
            tap((results) => {
              this.loading$.next(false);
              this.lastResult = results;
            }),
          )),
        shareReplay(1),
      ),
    );
  }

  /**
   * Append a new request for the given request value and pass
   * that to the switchmap handler
   * @param newValue
   */
  public request(newValue:T) {
    this.input$.next(newValue);
  }

  /**
   * Returns whether the last results returned anything
   */
  public get hasResults() {
    return this.lastResult.length > 0;
  }

  /**
   * Observe the switched response
   */
  public observe(until:Observable<unknown>) {
    return this
      .output$
      .pipe(
        takeUntil(until),
      );
  }
}
