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

import { ApiV3Filter } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3WorkPackagesPaths } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-packages-paths';
import { Observable, of, throwError } from 'rxjs';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { States } from 'core-app/core/states/states.service';
import { TestBed } from '@angular/core/testing';
import { type Mock } from 'vitest';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';

describe('ApiV3WorkPackagesPaths', () => {
  let workPackages:ApiV3WorkPackagesPaths;
  let getAllPaginated:Mock;

  const respondWith = (...responses:Observable<WorkPackageCollectionResource[]>[]) =>
    responses.forEach((response) => getAllPaginated.mockReturnValueOnce(response));

  const collection = (...ids:number[]):WorkPackageCollectionResource =>
    ({ elements: ids.map((id) => ({ id })) } as unknown as WorkPackageCollectionResource);

  const paramsOfCall = (index:number) => getAllPaginated.mock.calls[index][1] as Record<string, unknown>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        States,
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    });

    workPackages = TestBed.inject(ApiV3Service).work_packages;
    getAllPaginated = vi.spyOn(workPackages.halResourceService, 'getAllPaginated');
    vi.spyOn(workPackages.cache, 'updateWorkPackageList').mockReturnValue(undefined);
  });

  describe('requireAll', () => {
    it('does not request anything for an empty set of ids', async () => {
      await workPackages.requireAll([]);

      expect(getAllPaginated).not.toHaveBeenCalled();
    });

    it('requests every id only once', async () => {
      respondWith(of([collection(1, 2)]));

      await workPackages.requireAll(['1', '2', '1']);

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
      expect(paramsOfCall(0).filters).toEqual(ApiV3Filter('id', '=', ['1', '2']).toJson());
    });

    it('sends no timestamps when none are given', async () => {
      respondWith(of([collection(1)]));

      await workPackages.requireAll(['1']);

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
      expect(paramsOfCall(0)).not.toHaveProperty('timestamps');
    });

    it('sends no timestamps when an empty list is given', async () => {
      respondWith(of([collection(1)]));

      await workPackages.requireAll(['1'], []);

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
      expect(paramsOfCall(0)).not.toHaveProperty('timestamps');
    });

    it('sends timestamps joined by a comma', async () => {
      respondWith(of([collection(1)]));

      await workPackages.requireAll(['1'], ['2026-01-10T00:00:00Z', 'PT0S']);

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
      expect(paramsOfCall(0).timestamps).toEqual('2026-01-10T00:00:00Z,PT0S');
    });

    it('does not load anything again when all work packages existed at timestamps', async () => {
      respondWith(of([collection(1, 2)]));

      await workPackages.requireAll(['1', '2'], ['2026-01-10T00:00:00Z']);

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
    });

    it('loads current state of work packages missing at timestamps', async () => {
      respondWith(
        of([collection(1)]),
        of([collection(2)]),
      );

      await workPackages.requireAll(['1', '2'], ['2026-01-10T00:00:00Z']);

      expect(getAllPaginated).toHaveBeenCalledTimes(2);
      expect(paramsOfCall(0).timestamps).toEqual('2026-01-10T00:00:00Z');
      expect(paramsOfCall(1).filters).toEqual(ApiV3Filter('id', '=', ['2']).toJson());
      expect(paramsOfCall(1)).not.toHaveProperty('timestamps');
    });

    it('does not load missing work packages again when no timestamps are given', async () => {
      respondWith(of([collection(1)]));

      await workPackages.requireAll(['1', '2']);

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
    });

    it('rejects when first request fails', async () => {
      respondWith(throwError(() => new Error('request failed')));

      await expect(workPackages.requireAll(['1'], ['2026-01-10T00:00:00Z'])).rejects.toThrow('request failed');

      expect(getAllPaginated).toHaveBeenCalledTimes(1);
    });

    it('rejects when second request fails', async () => {
      respondWith(
        of([collection(1)]),
        throwError(() => new Error('fallback failed')),
      );

      await expect(workPackages.requireAll(['1', '2'], ['2026-01-10T00:00:00Z'])).rejects.toThrow('fallback failed');

      expect(getAllPaginated).toHaveBeenCalledTimes(2);
    });
  });
});
