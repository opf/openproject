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

import { DestroyRef, Injector } from '@angular/core';
import { onDestroySafely, runCleanup } from './owned-ui-cleanup';

describe('owned UI cleanup', () => {
  afterEach(() => vi.restoreAllMocks());
  it('reports the original cleanup failure', () => {
    const error = new Error('cleanup');
    const report = vi.fn();
    runCleanup(() => { throw error; }, report);
    expect(report).toHaveBeenCalledExactlyOnceWith(error);
  });

  it('isolates a failing reporter and logs both original errors', () => {
    const error = new Error('cleanup');
    const reportError = new Error('report');
    const log = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    expect(() => runCleanup(() => { throw error; }, () => { throw reportError; })).not.toThrow();
    expect(log).toHaveBeenCalledExactlyOnceWith(error, reportError);
  });

  it('lets later native callbacks run after an owned callback throws', () => {
    const injector = Injector.create({ providers: [] });
    const ref = injector.get(DestroyRef);
    const error = new Error('cleanup');
    const report = vi.fn();
    const next = vi.fn();
    onDestroySafely(ref, () => { throw error; }, report);
    onDestroySafely(ref, next);
    injector.destroy();
    expect(report).toHaveBeenCalledExactlyOnceWith(error);
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('returns the native unregister function', () => {
    const injector = Injector.create({ providers: [] });
    const cleanup = vi.fn();
    onDestroySafely(injector.get(DestroyRef), cleanup)();
    injector.destroy();
    expect(cleanup).not.toHaveBeenCalled();
  });

  it('skips registration on an already-destroyed native ref', () => {
    const injector = Injector.create({ providers: [] });
    const ref = injector.get(DestroyRef);
    injector.destroy();
    const cleanup = vi.fn();
    expect(() => onDestroySafely(ref, cleanup)()).not.toThrow();
    expect(cleanup).not.toHaveBeenCalled();
  });
});
