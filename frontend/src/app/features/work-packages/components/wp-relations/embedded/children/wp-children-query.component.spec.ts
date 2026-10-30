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

import { ChangeDetectorRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { EMPTY, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { initializeHalResourceConfig } from 'core-app/features/hal/services/hal-resource.config';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageRelationsHierarchyComponent } from '../../wp-relations-hierarchy/wp-relations-hierarchy.directive';
import { WorkPackageRelationsHierarchyService } from '../../wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageRelationsService } from '../../wp-relations.service';
import { WorkPackageInlineCreateService } from '../../../wp-inline-create/wp-inline-create.service';
import { WorkPackageChildrenQueryComponent } from './wp-children-query.component';

describe('children query input contracts', () => {
  let resource:WorkPackageResource;
  let factory:HalResourceService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(), provideHttpClientTesting(),
        { provide: PaginationService, useValue: {} },
        { provide: ApiV3Service, useValue: { work_packages: { id: () => ({ requireAndStream: () => EMPTY, observe: () => EMPTY }) } } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ChangeDetectorRef, useValue: { detectChanges: vi.fn() } },
        { provide: SchemaCacheService, useValue: { getSchemaHref: (wp:WorkPackageResource) => wp.$links.schema.href, requireAndStream: () => EMPTY } },
        { provide: HalEventsService, useValue: {} },
        { provide: WorkPackageRelationsService, useValue: {} },
        { provide: WorkPackageRelationsHierarchyService, useValue: {} },
        { provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: new Subject<string>() } },
      ],
    });
    factory = TestBed.inject(HalResourceService);
    initializeHalResourceConfig(factory)();
    resource = factory.createHalResourceOfType<WorkPackageResource>('WorkPackage', {
      id: 42,
      _links: {
        self: { href: '/api/v3/work_packages/42' },
        schema: { href: '/api/v3/work_packages/schemas/1-1' },
      },
    });
  });

  it('passes the hierarchy request parameters through the real child-query consumer', () => {
    const hierarchy = TestBed.runInInjectionContext(() => new WorkPackageRelationsHierarchyComponent());
    hierarchy.workPackage = resource;
    hierarchy.ngOnInit();
    const childQuery = TestBed.runInInjectionContext(() => new WorkPackageChildrenQueryComponent());
    childQuery.workPackage = resource;
    Object.assign(childQuery, { query: hierarchy.childrenQueryProps });
    childQuery.ngOnInit();

    expect(childQuery.queryProps).toBe(hierarchy.childrenQueryProps);
    expect(childQuery.queryProps).toEqual({
      filters: JSON.stringify([{ parent: { operator: '=', values: ['42'] } }]),
      'columns[]': ['id', 'type', 'subject', 'status'],
      showHierarchies: false,
    });
  });

  it('serializes a HAL query while retaining contextual request options', () => {
    const childQuery = TestBed.runInInjectionContext(() => new WorkPackageChildrenQueryComponent());
    childQuery.workPackage = resource;
    childQuery.query = factory.createHalResourceOfType<QueryResource>('Query', {
      columns: [], filters: [], sortBy: [], timestamps: [], showHierarchies: true,
    });
    childQuery.ngOnInit();

    expect(childQuery.queryProps).toMatchObject({ valid_subset: true, showHierarchies: true, filters: '[]' });
    expect(TestBed.inject(WorkPackageInlineCreateService).referenceTarget).toBe(resource);
  });
});
