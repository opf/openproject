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

import { vi } from 'vitest';
import { TurboRequestScope } from './request-scope';

describe('TurboRequestScope', () => {
  function deferred<T>() {
    let resolve!:(value:T) => void;
    let reject!:(error:Error) => void;
    const promise = new Promise<T>((res, rej) => {
      resolve = res;
      reject = rej;
    });

    return { promise, resolve, reject };
  }

  it('starts idle', () => {
    expect(new TurboRequestScope().busy).toBe(false);
  });

  it('is busy while a tracked operation is pending', async () => {
    const scope = new TurboRequestScope();
    const operation = deferred<string>();

    const tracked = scope.track(() => operation.promise);

    expect(scope.busy).toBe(true);

    operation.resolve('done');

    await expect(tracked).resolves.toBe('done');
    expect(scope.busy).toBe(false);
  });

  it('stays busy until every overlapping operation has settled', async () => {
    const scope = new TurboRequestScope();
    const first = deferred<void>();
    const second = deferred<void>();

    const trackedFirst = scope.track(() => first.promise);
    const trackedSecond = scope.track(() => second.promise);

    first.resolve();
    await trackedFirst;

    expect(scope.busy).toBe(true);

    second.resolve();
    await trackedSecond;

    expect(scope.busy).toBe(false);
  });

  it('releases on rejection and rethrows', async () => {
    const scope = new TurboRequestScope();
    const operation = deferred<void>();

    const tracked = scope.track(() => operation.promise);
    operation.reject(new Error('boom'));

    await expect(tracked).rejects.toThrow('boom');
    expect(scope.busy).toBe(false);
  });

  it('keeps scopes independent', async () => {
    const one = new TurboRequestScope();
    const other = new TurboRequestScope();
    const operation = deferred<void>();

    const tracked = one.track(() => operation.promise);

    expect(other.busy).toBe(false);

    operation.resolve();
    await tracked;
  });

  it('notifies subscribers on busy transitions only', async () => {
    const scope = new TurboRequestScope();
    const listener = vi.fn();
    const first = deferred<void>();
    const second = deferred<void>();

    scope.subscribe(listener);
    const trackedFirst = scope.track(() => first.promise);
    const trackedSecond = scope.track(() => second.promise);

    expect(listener).toHaveBeenCalledOnce();

    first.resolve();
    await trackedFirst;

    expect(listener).toHaveBeenCalledOnce();

    second.resolve();
    await trackedSecond;

    expect(listener).toHaveBeenCalledTimes(2);
  });

  it('stops notifying after unsubscribe', async () => {
    const scope = new TurboRequestScope();
    const listener = vi.fn();
    const operation = deferred<void>();

    const unsubscribe = scope.subscribe(listener);
    unsubscribe();

    const tracked = scope.track(() => operation.promise);
    operation.resolve();
    await tracked;

    expect(listener).not.toHaveBeenCalled();
  });
});
