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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { EMPTY, Observable, Subject } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

/**
 * Runs the most recently started request only: starting a request cancels the one
 * before it, so responses arriving out of order cannot replace newer results.
 */
export class LatestOnly {
  private readonly requests = new Subject<Observable<unknown>>();

  private readonly running = this.requests
    .pipe(switchMap((request) => request))
    .subscribe();

  private readonly applied = new Subject<unknown>();

  /** Emits each result right after it was applied. */
  readonly applied$ = this.applied.asObservable();

  /** The promise returned for the most recently started request. */
  latest:Promise<void> = Promise.resolve();

  /**
   * @returns a promise that resolves once the result was applied and rejects when the
   * request fails. A request that is superseded settles as the one replacing it does.
   */
  apply<T>(request:Observable<T>, onResult:(result:T) => void):Promise<void> {
    if (this.running.closed) return Promise.resolve();

    let settle!:{ resolve:(successor?:Promise<void>) => void, reject:(error:Error) => void };
    const started = new Promise<void>((resolve, reject) => {
      settle = { resolve, reject };
    });
    // Assigned before the request starts, so that the request it supersedes can settle with it.
    this.latest = started;

    this.requests.next(request.pipe(
      tap((result) => {
        onResult(result);
        this.applied.next(result);
      }),
      catchError((error:unknown) => {
        settle.reject(error instanceof Error ? error : new Error('Request failed', { cause: error }));
        return EMPTY;
      }),
      finalize(() => settle.resolve(this.latest === started ? undefined : this.latest)),
    ));

    return started;
  }

  cancel():void {
    this.running.unsubscribe();
  }
}
