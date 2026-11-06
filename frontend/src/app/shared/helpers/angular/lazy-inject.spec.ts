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

import { InjectionToken, Injector, runInInjectionContext } from '@angular/core';
import { expectTypeOf } from 'vitest';
import { lazyInject } from './lazy-inject';

describe('lazyInject', () => {
  const token = new InjectionToken<string>('lazy value');

  it('defers injector and service resolution until each read', () => {
    let current = Injector.create({ providers: [{ provide: token, useValue: 'first' }] });
    const injector = vi.fn(() => current);
    const value = lazyInject(token, { injector });

    expect(injector).not.toHaveBeenCalled();
    expect(value()).toBe('first');

    current = Injector.create({ providers: [{ provide: token, useValue: 'replacement' }] });
    expect(value()).toBe('replacement');
    expect(injector).toHaveBeenCalledTimes(2);
    expectTypeOf(value).toEqualTypeOf<() => string>();
  });

  it('captures the context injector without eagerly resolving a provider', () => {
    const factory = vi.fn(() => 'provided');
    const injector = Injector.create({ providers: [{ provide: token, useFactory: factory }] });
    const value = runInInjectionContext(injector, () => lazyInject(token));

    expect(factory).not.toHaveBeenCalled();
    expect(value()).toBe('provided');
  });

  it('throws on access for a missing required provider', () => {
    const injector = Injector.create({ providers: [] });
    const value = lazyInject(token, { injector: () => injector });

    expect(() => value()).toThrow();
  });

  it('returns an explicit null default with nullable typing', () => {
    const injector = Injector.create({ providers: [] });
    const value = lazyInject(token, { injector: () => injector, defaultValue: null });

    expect(value()).toBeNull();
    expectTypeOf(value).toEqualTypeOf<() => string|null>();
  });

  it('returns a supplied non-null fallback', () => {
    const injector = Injector.create({ providers: [] });
    const value = lazyInject(token, { injector: () => injector, defaultValue: 'fallback' });

    expect(value()).toBe('fallback');
    expectTypeOf(value).toEqualTypeOf<() => string>();
  });

  it('keeps a non-null fallback type for optional lookup', () => {
    const injector = Injector.create({ providers: [] });
    const value = lazyInject(token, { injector: () => injector, optional: true, defaultValue: 'fallback' });

    expect(value()).toBe('fallback');
    expectTypeOf(value).toEqualTypeOf<() => string>();
  });

  it('keeps optional lookup nullable when its fallback is undefined', () => {
    const optionalToken = new InjectionToken<string|undefined>('possibly undefined');
    const injector = Injector.create({ providers: [] });
    const value = lazyInject(optionalToken, { injector: () => injector, optional: true, defaultValue: undefined });

    expect(value()).toBeNull();
    expectTypeOf(value).toEqualTypeOf<() => string|undefined|null>();
  });

  it('returns null for optional lookup with nullable typing', () => {
    const injector = Injector.create({ providers: [] });
    const value = lazyInject(token, { injector: () => injector, optional: true });

    expect(value()).toBeNull();
    expectTypeOf(value).toEqualTypeOf<() => string|null>();
  });

  it('respects self and skipSelf lookup options', () => {
    const parent = Injector.create({ providers: [{ provide: token, useValue: 'parent' }] });
    const injector = Injector.create({ providers: [{ provide: token, useValue: 'child' }], parent });

    expect(lazyInject(token, { injector: () => injector, self: true })()).toBe('child');
    expect(lazyInject(token, { injector: () => injector, skipSelf: true })()).toBe('parent');
  });
});
