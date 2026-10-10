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
import { Observable, of, throwError } from 'rxjs';
import { delay } from 'rxjs/operators';
import { States } from 'core-app/core/states/states.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SubmenuService } from 'core-app/core/main-menu/submenu.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import {
  WorkPackageViewPaginationService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackagesQueryViewService } from 'core-app/features/work-packages/components/wp-list/wp-query-view.service';
import { WorkPackagesListService } from './wp-list.service';
import { WorkPackageStatesInitializationService } from './wp-states-initialization.service';
import { WorkPackagesListInvalidQueryService } from './wp-list-invalid-query.service';

describe('WorkPackagesListService', () => {
  let service:WorkPackagesListService;
  let querySpace:IsolatedQuerySpace;
  let load:ReturnType<typeof vi.fn>;

  const formFor = (href:string) => ({ href }) as QueryFormResource;
  const queryFor = (href:string) => ({ $links: { update: { href } } }) as unknown as QueryResource;

  const givenLoadedForm = (form:QueryFormResource, source:Observable<unknown> = of([form, {}])) => {
    load.mockReturnValueOnce(source);
  };

  beforeEach(async () => {
    load = vi.fn();

    const apiV3ServiceStub = { queries: { form: { load } } };
    const wpStatesInitializationStub = {
      updateStatesFromForm: vi.fn((_query:QueryResource, form:QueryFormResource) => {
        querySpace?.queryForm.putValue(form);
      }),
    };

    await TestBed.configureTestingModule({
      providers: [
        States,
        IsolatedQuerySpace,
        { provide: ApiV3Service, useValue: apiV3ServiceStub },
        { provide: WorkPackageStatesInitializationService, useValue: wpStatesInitializationStub },
        { provide: AuthorisationService, useValue: {} },
        { provide: ConfigurationService, useValue: {} },
        { provide: CurrentUserService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: PaginationService, useValue: {} },
        { provide: SubmenuService, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: UrlParamsHelperService, useValue: {} },
        { provide: UrlParamsService, useValue: {} },
        { provide: WorkPackageViewPaginationService, useValue: {} },
        { provide: WorkPackagesListInvalidQueryService, useValue: {} },
        { provide: WorkPackagesQueryViewService, useValue: {} },
        WorkPackagesListService,
      ],
    }).compileComponents();

    service = TestBed.inject(WorkPackagesListService);
    querySpace = TestBed.inject(IsolatedQuerySpace);
  });

  describe('conditionallyLoadForm', () => {
    it('issues a single request when called concurrently for the same query', async () => {
      const form = formFor('/api/v3/queries/form');
      givenLoadedForm(form, of([form, {}]).pipe(delay(1)));

      const results = await Promise.all([
        service.conditionallyLoadForm(queryFor('/api/v3/queries/form')),
        service.conditionallyLoadForm(queryFor('/api/v3/queries/form')),
      ]);

      expect(load).toHaveBeenCalledTimes(1);
      expect(results).toEqual([form, form]);
    });

    it('reuses the loaded form once it is in the query space', async () => {
      const form = formFor('/api/v3/queries/form');
      givenLoadedForm(form);

      await service.conditionallyLoadForm(queryFor('/api/v3/queries/form'));
      const reused = await service.conditionallyLoadForm(queryFor('/api/v3/queries/form'));

      expect(load).toHaveBeenCalledTimes(1);
      expect(reused).toBe(form);
    });

    it('loads again when the query points to a different form', async () => {
      const first = formFor('/api/v3/queries/form');
      const second = formFor('/api/v3/queries/42/form');
      givenLoadedForm(first);
      givenLoadedForm(second);

      await service.conditionallyLoadForm(queryFor('/api/v3/queries/form'));
      const reloaded = await service.conditionallyLoadForm(queryFor('/api/v3/queries/42/form'));

      expect(load).toHaveBeenCalledTimes(2);
      expect(reloaded).toBe(second);
    });

    it('retries after a failed request instead of caching the rejection', async () => {
      const form = formFor('/api/v3/queries/form');
      load.mockReturnValueOnce(throwError(() => new Error('boom')));
      givenLoadedForm(form);

      await expect(service.conditionallyLoadForm(queryFor('/api/v3/queries/form'))).rejects.toThrow('boom');
      const retried = await service.conditionallyLoadForm(queryFor('/api/v3/queries/form'));

      expect(load).toHaveBeenCalledTimes(2);
      expect(retried).toBe(form);
    });
  });
});
