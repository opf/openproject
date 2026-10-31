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

import { expectTypeOf } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { States } from 'core-app/core/states/states.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import {
  UserSelection,
  createUserSelectionAdapter,
  decodeUserSelection,
  userSelectionToResource,
} from './user-selection';
import { SelectionAdapter } from './selection-adapter';

expectTypeOf<Date>().not.toExtend<UserSelection>();
expectTypeOf<{ unrelated:true }>().not.toExtend<UserSelection>();
expectTypeOf<{ id:7; name:'Ada'; href:null }[]>().not.toExtend<UserSelection>();
expectTypeOf<SelectionAdapter<UserSelection>['setValue']>().parameter(0).toEqualTypeOf<UserSelection>();

describe('decodeUserSelection', () => {
  let halResourceService:HalResourceService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [States, provideHttpClient(), provideHttpClientTesting()],
    });
    halResourceService = TestBed.inject(HalResourceService);
  });

  it.each([null, undefined, { href: null }])('decodes %o as an empty selection', (raw) => {
    expect(decodeUserSelection(raw)).toEqual({ ok: true, value: null });
  });

  it.each([0, 7, '7'])('decodes the scalar ID %o as a reference', (id) => {
    expect(decodeUserSelection(id)).toEqual({ ok: true, value: { kind: 'reference', reference: { id } } });
  });

  it('decodes a complete DTO as an option', () => {
    const option = { id: 7, name: 'Ada', href: '/api/v3/users/7', email: 'ada@example.com', avatar: null };

    expect(decodeUserSelection(option)).toEqual({ ok: true, value: { kind: 'option', option } });
  });

  it('keeps only the typed fields of an option', () => {
    const decoded = decodeUserSelection({ id: 7, name: 'Ada', href: null, extra: true });

    expect(decoded).toEqual({ ok: true, value: { kind: 'option', option: { id: 7, name: 'Ada', href: null } } });
  });

  it('keeps the empty name of a HAL user', () => {
    const user = halResourceService.createHalResourceOfType('user', {
      id: 7,
      name: '',
      _links: { self: { href: '/api/v3/users/7' } },
    });

    expect(decodeUserSelection(user)).toEqual({
      ok: true,
      value: { kind: 'option', option: { id: '7', name: '', href: '/api/v3/users/7' } },
    });
  });

  it('decodes an identity without a name as a reference', () => {
    expect(decodeUserSelection({ id: 7, href: '/api/v3/users/7' })).toEqual({
      ok: true,
      value: { kind: 'reference', reference: { id: 7, href: '/api/v3/users/7' } },
    });
  });

  it('decodes a link-only object as a reference', () => {
    expect(decodeUserSelection({ href: '/api/v3/users/7', name: 'Ada' })).toEqual({
      ok: true,
      value: { kind: 'reference', reference: { href: '/api/v3/users/7', name: 'Ada' } },
    });
  });

  it('decodes a loaded HAL user as an option through its getters', () => {
    const user = halResourceService.createHalResourceOfType('user', {
      id: 7,
      name: 'Ada',
      email: 'ada@example.com',
      _links: { self: { href: '/api/v3/users/7' } },
    });

    expect(decodeUserSelection(user)).toEqual({
      ok: true,
      value: { kind: 'option', option: { id: '7', name: 'Ada', href: '/api/v3/users/7', email: 'ada@example.com' } },
    });
  });

  it('decodes an invited HAL user as an option with its href', () => {
    const invited = halResourceService.createHalResource({
      _type: 'User',
      id: 12,
      name: 'invitee@example.com',
      email: 'invitee@example.com',
      _links: { self: { href: '/api/v3/users/12', title: 'invitee@example.com' } },
    });

    const decoded = decodeUserSelection(invited);

    expect(decoded).toEqual({
      ok: true,
      value: {
        kind: 'option',
        option: { id: '12', name: 'invitee@example.com', href: '/api/v3/users/12', email: 'invitee@example.com' },
      },
    });
  });

  it('decodes a HAL link without a name as a reference', () => {
    const linked = halResourceService.createHalResource({ _links: { self: { href: '/api/v3/users/7' } } }, false);

    expect(decodeUserSelection(linked)).toEqual({
      ok: true,
      value: { kind: 'reference', reference: { id: '7', href: '/api/v3/users/7' } },
    });
  });

  it.each([
    { id: '7', name: 7 },
    { id: 7, name: 'Ada', href: 7 },
    { id: 7, name: 'Ada', href: '' },
    { id: 7, name: 'Ada', href: null, email: 3 },
    { id: 7, name: 'Ada', href: null, avatar: {} },
    { id: false },
    { id: Number.NaN, href: '/api/v3/users/7' },
    { unrelated: true },
    new Date(),
    true,
    Number.POSITIVE_INFINITY,
  ])('rejects %o as an invalid shape', (raw) => {
    expect(decodeUserSelection(raw)).toEqual({ ok: false, issue: { code: 'invalid-shape' } });
  });

  it('rejects a draft without identity as unsupported', () => {
    expect(decodeUserSelection({ id: null, href: null, name: 'New user' })).toEqual({
      ok: false,
      issue: { code: 'unsupported-selection' },
    });
  });

  it.each([[[]], [[{ id: 7, name: 'Ada', href: null }]]])('rejects the array %o as the wrong cardinality', (raw) => {
    expect(decodeUserSelection(raw)).toEqual({ ok: false, issue: { code: 'wrong-cardinality' } });
  });
});

describe('createUserSelectionAdapter', () => {
  beforeEach(() => {
    vi.stubGlobal('ErrorReporter', { captureMessage: vi.fn() });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('starts empty and keeps an invalid change from emitting', () => {
    const adapter = createUserSelectionAdapter();
    const emitted = vi.fn();
    adapter.changes$.subscribe(emitted);

    adapter.bridge.accept({ id: '7', name: 7 });

    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape' }, lastAccepted: null });
    expect(emitted).not.toHaveBeenCalled();
  });

  it('displays a typed value through its raw model', () => {
    const adapter = createUserSelectionAdapter();
    const option = { id: 7, name: 'Ada', href: '/api/v3/users/7' };

    adapter.setValue({ kind: 'option', option });

    expect(adapter.bridge.model).toEqual(option);
  });

  it('compares raw items by href, then ID, never by missing identity', () => {
    const { compareWith, trackBy } = createUserSelectionAdapter().bridge;

    expect(compareWith({ href: '/api/v3/users/7', name: 'A' }, { href: '/api/v3/users/7', name: 'B' })).toBe(true);
    expect(compareWith({ id: 0, href: null }, { id: '0' })).toBe(true);
    expect(compareWith({ name: 'Ada' }, { name: 'Ada' })).toBe(false);
    expect(compareWith({ id: 7, href: '/api/v3/users/7' }, { id: 7, href: '/api/v3/users/8' })).toBe(false);
    expect(trackBy({ id: 0, href: null })).toBe(0);
    expect(trackBy({ id: 7, href: '/api/v3/users/7' })).toBe('/api/v3/users/7');
    expect(trackBy({ name: 'Ada' })).toBeUndefined();
  });
});

describe('userSelectionToResource', () => {
  let deps:{ halResourceService:HalResourceService; apiV3Service:ApiV3Service };
  let http:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [States, provideHttpClient(), provideHttpClientTesting()],
    });
    deps = { halResourceService: TestBed.inject(HalResourceService), apiV3Service: TestBed.inject(ApiV3Service) };
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    http.expectNone(() => true);
    http.verify();
  });

  it('returns null for an empty selection', () => {
    expect(userSelectionToResource(null, deps)).toBeNull();
  });

  it('builds a user resource from an option, keeping its name and email', () => {
    const resource = userSelectionToResource(
      { kind: 'option', option: { id: 7, name: 'Ada', href: '/api/v3/users/7', email: 'ada@example.com' } },
      deps,
    );

    expect(resource).toBeInstanceOf(HalResource);
    expect(resource?.$halType).toBe('user');
    expect(resource?.href).toBe('/api/v3/users/7');
    expect(resource?.name).toBe('Ada');
    expect(resource?.$source.email).toBe('ada@example.com');
  });

  it('builds a reference by ID from the users path', () => {
    const resource = userSelectionToResource({ kind: 'reference', reference: { id: 7 } }, deps);

    expect(resource?.$halType).toBe('user');
    expect(resource?.href).toBe('/api/v3/users/7');
    expect(resource?.id).toBe('7');
  });

  it('keeps the supplied href and name of a reference', () => {
    const resource = userSelectionToResource(
      { kind: 'reference', reference: { href: '/api/v3/placeholder_users/3', name: 'Placeholder' } },
      deps,
    );

    expect(resource?.href).toBe('/api/v3/placeholder_users/3');
    expect(resource?.name).toBe('Placeholder');
  });

  it('builds the href of an option without one from the users path', () => {
    const resource = userSelectionToResource({ kind: 'option', option: { id: 7, name: 'Ada', href: null } }, deps);

    expect(resource?.href).toBe('/api/v3/users/7');
    expect(resource?.name).toBe('Ada');
  });
});
