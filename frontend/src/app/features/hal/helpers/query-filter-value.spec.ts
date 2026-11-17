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
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import {
  isQueryFilterValue,
  QueryFilterValue,
  queryFilterValueId,
  serializeQueryFilterValue,
} from 'core-app/features/hal/helpers/query-filter-value';
import { decodeEntityReference } from 'core-app/shared/types/entity-reference';

describe('queryFilterValueId', () => {
  let halResourceService:HalResourceService;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        HalResourceService,
        States,
        I18nService,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    }).compileComponents();
    halResourceService = TestBed.inject(HalResourceService);
  });

  it('serializes a resource without a numeric ID by its link', () => {
    const me = halResourceService.createHalResource({ _links: { self: { href: '/api/v3/users/me' } } }, true);

    expect(queryFilterValueId(me)).toBe('me');
  });

  it('serializes a resource by its ID', () => {
    const user = halResourceService.createHalResource({ id: 5, _links: { self: { href: '/api/v3/users/5' } } }, true);

    expect(queryFilterValueId(user)).toBe('5');
  });

  it.each([0, '7', ''])('passes the scalar %j through', (value) => {
    expect(queryFilterValueId(value)).toBe(value);
  });

  it('serializes a plain reference by its ID', () => {
    expect(queryFilterValueId({ id: 42, href: '/api/v3/projects/42' })).toBe(42);
  });

  it('serializes a plain reference without an ID by its link', () => {
    expect(queryFilterValueId({ href: '/api/v3/projects/42' })).toBe('42');
  });

  it('keeps ID 0 of a reference', () => {
    expect(queryFilterValueId({ id: 0 })).toBe(0);
  });

  it('derives the ID of a link reference from its href', () => {
    expect(queryFilterValueId({ href: '/api/v3/work_packages/{id}' })).toBe('{id}');
  });

  it('returns null for a resource without an ID or link', () => {
    const empty = halResourceService.createHalResource({}, true);

    expect(queryFilterValueId(empty)).toBeNull();
  });
});

describe('serializeQueryFilterValue', () => {
  let halResourceService:HalResourceService;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        HalResourceService,
        States,
        I18nService,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    }).compileComponents();
    halResourceService = TestBed.inject(HalResourceService);
  });

  it.each([
    [true, 't'],
    [false, 'f'],
    ['', ''],
    [0, '0'],
    ['7', '7'],
    [{ id: 3 }, '3'],
    [{ href: '/api/v3/users/me' }, 'me'],
    [{ href: '/api/v3/users/a%20b' }, 'a%20b'],
    [{ href: '/api/v3/users/100%' }, '100%'],
  ])('serializes %j as %j', (value, param) => {
    expect(serializeQueryFilterValue(value)).toEqual({ ok: true, param });
  });

  it('fails for a resource without identity', () => {
    const empty = halResourceService.createHalResource({}, true);

    expect(serializeQueryFilterValue(empty)).toEqual({ ok: false, code: 'missing-identity' });
  });
});

describe('decodeEntityReference', () => {
  it.each([
    ['a zero ID', { id: 0 }],
    ['a link reference', { href: '/api/v3/work_packages/{id}' }],
  ])('accepts %s', (_label, value) => {
    expect(decodeEntityReference(value)).toEqual(value);
  });

  it.each([
    ['an empty object', {}],
    ['a null link', { href: null }],
    ['a blank link', { href: '' }],
    ['a boolean ID', { id: false }],
    ['a non-finite ID', { id: Number.NaN }],
    ['a non-string name', { id: 1, name: 1 }],
    ['an array', []],
    ['a date', new Date()],
  ])('rejects %s', (_label, value) => {
    expect(decodeEntityReference(value)).toBeNull();
  });
});

describe('isQueryFilterValue', () => {
  it.each([
    ['a scalar ID', '7'],
    ['a zero ID', 0],
    ['an ID reference', { id: 0, name: 'Zero' }],
    ['a link reference', { href: '/api/v3/work_packages/{id}' }],
  ])('accepts %s', (_label, value) => {
    expect(isQueryFilterValue(value)).toBe(true);
  });

  it.each([
    ['null', null],
    ['an array', []],
    ['a date', new Date()],
    ['an object without identity', { name: 'Unrelated' }],
    ['a boolean ID', { id: false }],
    ['an empty link', { href: null }],
    ['a blank link', { href: '' }],
    ['a non-finite ID', { id: Number.NaN }],
    ['a non-string name', { id: 1, name: 1 }],
  ])('rejects %s', (_label, value) => {
    expect(isQueryFilterValue(value)).toBe(false);
  });
});

expectTypeOf({ href: '/api/v3/work_packages/{id}' }).toExtend<QueryFilterValue>();
expectTypeOf({ id: 7 }).toExtend<QueryFilterValue>();
expectTypeOf({ name: 'Unrelated' }).not.toExtend<QueryFilterValue>();
expectTypeOf({ href: null }).not.toExtend<QueryFilterValue>();
expectTypeOf(new Date()).not.toExtend<QueryFilterValue>();
expectTypeOf(queryFilterValueId).parameter(0).toEqualTypeOf<QueryFilterValue>();
