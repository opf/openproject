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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { firstValueFrom } from 'rxjs';

import { States } from 'core-app/core/states/states.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';

import { OpAutocompleterService } from './op-autocompleter.service';
import { TOpAutocompleterResource } from '../typings';

interface CreateParamsAccess {
  createParams:(resource:TOpAutocompleterResource) => Record<string, string>;
}

describe('OpAutocompleterService', () => {
  let service:OpAutocompleterService;
  let httpMock:HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        States,
        OpAutocompleterService,
        { provide: SchemaCacheService, useValue: { ensureLoaded: () => Promise.resolve() } },
        provideHttpClient(withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });

    const halResourceService = TestBed.inject(HalResourceService);
    halResourceService.registerResource('Collection', { cls: CollectionResource });
    halResourceService.registerResource('WorkPackage', { cls: WorkPackageResource });

    service = TestBed.inject(OpAutocompleterService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('work_packages select params', () => {
    it('requests elements/_type for work_packages', () => {
      const params = (service as unknown as CreateParamsAccess).createParams('work_packages');

      expect(params.select).toContain('elements/_type');
    });
  });

  describe('loadAvailable("work_packages")', () => {
    it('emits WorkPackageResource instances for elements typed as WorkPackage', async () => {
      const pending = firstValueFrom(service.loadAvailable('demo', 'work_packages'));

      const request = httpMock.expectOne((req) => req.url.startsWith('/api/v3/work_packages'));
      request.flush({
        _type: 'Collection',
        _links: { self: { href: request.request.url } },
        _embedded: {
          elements: [
            {
              _type: 'WorkPackage',
              id: 42,
              displayId: 'DEMO-7',
              subject: 'Pick me',
              _links: { self: { href: '/api/v3/work_packages/42' } },
            },
          ],
        },
        count: 1,
        total: 1,
        pageSize: 30,
        offset: 1,
      });

      const elements = await pending;

      expect(elements).toHaveLength(1);
      expect(elements[0]).toBeInstanceOf(WorkPackageResource);
      expect((elements[0] as WorkPackageResource).displayId).toBe('DEMO-7');
    });
  });
});
