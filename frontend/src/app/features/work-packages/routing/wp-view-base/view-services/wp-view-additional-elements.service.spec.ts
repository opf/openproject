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
import { throwError, of } from 'rxjs';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewAdditionalElementsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-additional-elements.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { DEFAULT_TIMESTAMP } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';

describe('WorkPackageViewAdditionalElementsService', () => {
  let service:WorkPackageViewAdditionalElementsService;
  let querySpace:IsolatedQuerySpace;
  let shareRequest:ReturnType<typeof vi.fn>;
  const notifications = { handleRawError: vi.fn() };
  const requireAll = vi.fn();

  const query = { timestamps: [DEFAULT_TIMESTAMP] } as unknown as QueryResource;
  const results = { elements: [{ id: '1' }] } as unknown as WorkPackageCollectionResource;

  beforeEach(async () => {
    vi.clearAllMocks();
    requireAll.mockResolvedValue(undefined);
    shareRequest = vi.fn().mockReturnValue(of([]));

    await TestBed.configureTestingModule({
      providers: [
        IsolatedQuerySpace,
        WorkPackageViewAdditionalElementsService,
        { provide: WorkPackageViewHierarchiesService, useValue: { isEnabled: false } },
        {
          provide: WorkPackageViewColumnsService,
          useValue: {
            hasRelationColumns: () => false,
            hasChildRelationsColumn: () => false,
            hasShareColumn: () => true,
          },
        },
        { provide: WorkPackageNotificationService, useValue: notifications },
        { provide: HalResourceService, useValue: {} },
        {
          provide: ApiV3Service,
          useValue: {
            work_packages: { requireAll },
            shares: { filtered: () => ({ getPaginatedResults: shareRequest }) },
          },
        },
        { provide: SchemaCacheService, useValue: {} },
        { provide: WorkPackageRelationsService, useValue: {} },
      ],
    }).compileComponents();

    service = TestBed.inject(WorkPackageViewAdditionalElementsService);
    querySpace = TestBed.inject(IsolatedQuerySpace);
  });

  it('marks the required work packages as loaded once they are', async () => {
    service.initialize(query, results);

    await vi.waitFor(() => expect(querySpace.additionalRequiredWorkPackages.hasValue()).toBe(true));
    expect(requireAll).toHaveBeenCalled();
    expect(notifications.handleRawError).not.toHaveBeenCalled();
  });

  it('reports a failed request for the required data and still marks the table as loaded', async () => {
    const error = new Error('shares unavailable');
    shareRequest.mockReturnValue(throwError(() => error));

    service.initialize(query, results);

    await vi.waitFor(() => expect(querySpace.additionalRequiredWorkPackages.hasValue()).toBe(true));
    expect(notifications.handleRawError).toHaveBeenCalledWith(error);
    expect(requireAll).not.toHaveBeenCalled();
  });
});
