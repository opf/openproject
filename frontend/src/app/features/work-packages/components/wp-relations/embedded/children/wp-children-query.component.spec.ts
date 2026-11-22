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

import { Component, Input, NO_ERRORS_SCHEMA, ChangeDetectorRef } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { EMPTY, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { GroupDescriptor } from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { initializeHalResourceConfig } from 'core-app/features/hal/services/hal-resource.config';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageRelationsHierarchyComponent } from '../../wp-relations-hierarchy/wp-relations-hierarchy.directive';
import { WorkPackageChildrenQueryComponent } from './wp-children-query.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-embedded-table',
  template: '',
  standalone: false,
})
class EmbeddedTableStubComponent {
  @Input() configuration:Record<string, unknown>;
}

describe('WorkPackageChildrenQueryComponent group heading', () => {
  let fixture:ComponentFixture<WorkPackageChildrenQueryComponent>;

  function mount(group?:GroupDescriptor) {
    TestBed.configureTestingModule({
      declarations: [WorkPackageChildrenQueryComponent, EmbeddedTableStubComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        { provide: WorkPackageRelationsHierarchyService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: HalEventsService, useValue: {} },
        { provide: ApiV3Service, useValue: { work_packages: { id: () => ({ observe: () => EMPTY }) } } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageRelationsService, useValue: {} },
        { provide: UrlParamsHelperService, useValue: {} },
      ],
    }).overrideComponent(WorkPackageChildrenQueryComponent, {
      set: { providers: [{ provide: WorkPackageInlineCreateService, useValue: { newInlineWorkPackageCreated: EMPTY } }] },
    });

    fixture = TestBed.createComponent(WorkPackageChildrenQueryComponent);
    fixture.componentInstance.workPackage = { project: { href: '/api/v3/projects/1' } } as unknown as WorkPackageResource;
    fixture.componentInstance.query = {};
    fixture.componentInstance.group = group;
    fixture.detectChanges();
  }

  const tableConfiguration = () => fixture.debugElement
    .query(By.directive(EmbeddedTableStubComponent))
    .componentInstance.configuration as Record<string, unknown>;

  it('labels the table by the group heading', () => {
    mount({ name: 'Children' } as GroupDescriptor);

    const heading = (fixture.nativeElement as HTMLElement).querySelector('h3.attributes-group--header-text')!;
    expect(heading.id).toMatch(/^wp-query-group-heading-/);
    expect(tableConfiguration().labelledBy).toBe(heading.id);
  });

  it('leaves the table unlabeled without a group', () => {
    mount();

    expect((fixture.nativeElement as HTMLElement).querySelector('h3')).toBeNull();
    expect(tableConfiguration().labelledBy).toBeNull();
  });
});

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
