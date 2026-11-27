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

import { TestBed } from '@angular/core/testing';
import { Subject, of, throwError } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { fallbackSchemaId, SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { States } from 'core-app/core/states/states.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';

describe('SchemaCacheService', () => {
  const href = '/api/v3/work_packages/schemas/1-1';

  let service:SchemaCacheService;
  let states:States;
  let halResourceService:HalResourceService;

  const schema = (name:string) => halResourceService.createHalResourceOfClass<SchemaResource>(
    SchemaResource,
    { _type: 'Schema', name },
    true,
  );
  const write = (value:SchemaResource) => states.schemas.get(href).putValue(value);
  const visit = () => document.dispatchEvent(new CustomEvent('op:page-visit'));
  const flush = () => new Promise((resolve) => setTimeout(resolve));

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [OpenprojectHalModule],
      providers: [
        States,
        HalResourceService,
        TimezoneService,
        SchemaCacheService,
        PathHelperService,
        { provide: ConfigurationService, useValue: {} },
        { provide: I18nService, useValue: { t: (..._args:unknown[]) => 'translation' } },
        { provide: ToastService, useValue: {} },
        { provide: HalResourceNotificationService, useValue: { handleRawError: () => false } },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    states = TestBed.inject(States);
    halResourceService = TestBed.inject(HalResourceService);
    service = TestBed.inject(SchemaCacheService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('expires a cached schema on a page visit', () => {
    write(schema('A'));
    expect(service.stale(href)).toBe(false);

    visit();

    expect(service.stale(href)).toBe(true);
  });

  it('does not expire without a page visit', () => {
    write(schema('A'));

    expect(service.stale(href)).toBe(false);
  });

  it('treats a value written after the visit as fresh', () => {
    write(schema('A'));
    visit();

    write(schema('B'));

    expect(service.stale(href)).toBe(false);
  });

  it('never expires the fallback schema', () => {
    visit();

    expect(service.stale(fallbackSchemaId)).toBe(false);
  });

  it('keeps the old value while revalidating', () => {
    const schemaA = schema('A');
    const schemaB = schema('B');
    const response = new Subject<SchemaResource>();
    vi.spyOn(halResourceService, 'get').mockReturnValue(response);
    write(schemaA);
    visit();

    service.requireAndStream(href).subscribe();

    expect(service.state(href).value).toBe(schemaA);
    response.next(schemaB);
    expect(service.state(href).value).toBe(schemaB);
  });

  it('ensureLoaded waits for the revalidated schema', async () => {
    const schemaB = schema('B');
    const response = new Subject<SchemaResource>();
    vi.spyOn(halResourceService, 'get').mockReturnValue(response);
    write(schema('A'));
    visit();

    let resolved:SchemaResource|undefined;
    const loaded = service.ensureLoaded(href).then((value) => { resolved = value; return value; });
    await flush();
    expect(resolved).toBeUndefined();

    response.next(schemaB);

    await expect(loaded).resolves.toBe(schemaB);
  });

  it('shares one request between concurrent callers', async () => {
    const schemaB = schema('B');
    const response = new Subject<SchemaResource>();
    const get = vi.spyOn(halResourceService, 'get').mockReturnValue(response);
    write(schema('A'));
    visit();

    const first = service.ensureLoaded(href);
    const second = service.ensureLoaded(href);
    response.next(schemaB);

    expect(get).toHaveBeenCalledTimes(1);
    await expect(first).resolves.toBe(schemaB);
    await expect(second).resolves.toBe(schemaB);
  });

  it('keeps and returns the old value when revalidation fails, then retries', async () => {
    const schemaA = schema('A');
    const get = vi.spyOn(halResourceService, 'get').mockReturnValue(throwError(() => new Error('offline')));
    write(schemaA);
    visit();

    await expect(service.ensureLoaded(href)).resolves.toBe(schemaA);
    expect(service.state(href).value).toBe(schemaA);
    expect(service.stale(href)).toBe(true);

    await service.ensureLoaded(href);
    expect(get).toHaveBeenCalledTimes(2);
  });

  it('lets a direct write during revalidation win over the older response', async () => {
    const schemaC = schema('C');
    const response = new Subject<SchemaResource>();
    vi.spyOn(halResourceService, 'get').mockReturnValue(response);
    write(schema('A'));
    visit();

    const loaded = service.ensureLoaded(href);
    write(schemaC);
    response.next(schema('B'));

    await loaded;
    expect(service.state(href).value).toBe(schemaC);
  });

  it('follows a newer visit\'s revalidation', async () => {
    const schemaB2 = schema('B2');
    const first = new Subject<SchemaResource>();
    const second = new Subject<SchemaResource>();
    const get = vi.spyOn(halResourceService, 'get')
      .mockReturnValueOnce(first)
      .mockReturnValueOnce(second);
    const schemaA = schema('A');
    write(schemaA);
    visit();

    const earlier = service.ensureLoaded(href);
    visit();
    const later = service.ensureLoaded(href);

    expect(get).toHaveBeenCalledTimes(2);
    first.next(schema('B1'));
    expect(service.state(href).value).toBe(schemaA);
    second.next(schemaB2);

    await expect(earlier).resolves.toBe(schemaB2);
    await expect(later).resolves.toBe(schemaB2);
    expect(service.stale(href)).toBe(false);
  });

  it('never lets an older response overwrite a write made after a later visit', async () => {
    const schemaC = schema('C');
    const first = new Subject<SchemaResource>();
    const second = new Subject<SchemaResource>();
    vi.spyOn(halResourceService, 'get')
      .mockReturnValueOnce(first)
      .mockReturnValueOnce(second);
    write(schema('A'));
    visit();

    void service.ensureLoaded(href);
    write(schemaC);
    visit();
    first.next(schema('B1'));
    await flush();

    expect(service.state(href).value).toBe(schemaC);
  });

  it('does not report stale while a forced load is pending', () => {
    const get = vi.spyOn(halResourceService, 'get').mockReturnValue(new Subject<SchemaResource>());
    write(schema('A'));
    visit();

    service.requireAndStream(href, true).subscribe();

    expect(service.stale(href)).toBe(false);
    service.requireAndStream(href).subscribe();
    expect(get).toHaveBeenCalledTimes(1);
  });

  it('does not let a load started before a visit satisfy the next visit', async () => {
    const schemaB2 = schema('B2');
    const first = new Subject<SchemaResource>();
    const second = new Subject<SchemaResource>();
    const get = vi.spyOn(halResourceService, 'get')
      .mockReturnValueOnce(first)
      .mockReturnValueOnce(second);

    const earlier = service.ensureLoaded(href);
    visit();
    const later = service.ensureLoaded(href);

    expect(get).toHaveBeenCalledTimes(2);
    first.next(schema('B1'));
    expect(service.state(href).hasValue()).toBe(false);
    second.next(schemaB2);

    await expect(earlier).resolves.toBe(schemaB2);
    await expect(later).resolves.toBe(schemaB2);
  });

  it('rejects when a cold load fails, then retries', async () => {
    const schemaA = schema('A');
    const failure = new Error('offline');
    const get = vi.spyOn(halResourceService, 'get')
      .mockReturnValueOnce(throwError(() => failure))
      .mockReturnValueOnce(of(schemaA));

    await expect(service.ensureLoaded(href)).rejects.toBe(failure);
    await expect(service.ensureLoaded(href)).resolves.toBe(schemaA);
    expect(get).toHaveBeenCalledTimes(2);
  });

  it('reloads an age-stale schema without clearing it', () => {
    vi.useFakeTimers({ toFake: ['Date'] });
    const schemaA = schema('A');
    const schemaB = schema('B');
    const response = new Subject<SchemaResource>();
    vi.spyOn(halResourceService, 'get').mockReturnValue(response);
    write(schemaA);
    vi.setSystemTime(Date.now() + (2 * 60 * 60 * 1000));

    service.requireAndStream(href).subscribe();

    expect(service.state(href).value).toBe(schemaA);
    response.next(schemaB);
    expect(service.state(href).value).toBe(schemaB);
  });

  it('loads a pristine schema without a visit', async () => {
    const schemaA = schema('A');
    vi.spyOn(halResourceService, 'get').mockReturnValue(of(schemaA));

    await expect(service.ensureLoaded(href)).resolves.toBe(schemaA);
  });
});
