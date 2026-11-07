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

import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { ChangeDetectorRef, Component, SimpleChange, input, output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { EMPTY, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { initializeHalResourceConfig } from 'core-app/features/hal/services/hal-resource.config';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { RelationsStateValue, WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { GroupDescriptor } from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { WorkPackageRelationQueryComponent } from '../relations/wp-relation-query.component';
import { WorkPackageChildrenQueryComponent } from './wp-children-query.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-embedded-table',
  template: `
    <table [attr.aria-labelledby]="configuration().labelledBy"></table>
    <button type="button" (click)="load()">Load query</button>
  `,
})
class EmbeddedTableStubComponent {
  readonly configuration = input.required<{ labelledBy:string|null }>();
  readonly queryProps = input.required<object>();
  readonly initialLoadingIndicator = input.required<boolean>();
  readonly tableActions = input.required<unknown[]>();
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  readonly onQueryLoaded = output<QueryResource>();

  loadedQuery:Promise<QueryResource>;

  async load():Promise<void> {
    this.onQueryLoaded.emit(await this.loadedQuery);
  }

  readonly isInitialized = true;
  readonly loadQuery = vi.fn();
}

describe('embedded relation queries', () => {
  let hal:HalResourceService;
  let workPackageChanges:Map<string, Subject<WorkPackageResource>>;
  let relationChanges:Map<string, Subject<RelationsStateValue>>;
  let updateCounter:ReturnType<typeof vi.fn>;

  beforeEach(() => {
    workPackageChanges = new Map();
    relationChanges = new Map();
    updateCounter = vi.fn();
    TestBed.configureTestingModule({
      declarations: [WorkPackageChildrenQueryComponent, WorkPackageRelationQueryComponent],
      imports: [EmbeddedTableStubComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: WorkPackageRelationsHierarchyService, useValue: {} },
        { provide: PathHelperService, useValue: { api: { v3: { apiV3Base: '/api/v3' } } } },
        { provide: CurrentUserService, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
        { provide: ApiV3Service, useValue: { work_packages: { id: (wp:WorkPackageResource) => ({ observe: () => workPackageChanges.get(wp.id!) }) } } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageRelationsService, useValue: { observe: (id:string) => relationChanges.get(id), updateCounter } },
        { provide: WorkPackageNotificationService, useValue: {} },
        { provide: UrlParamsHelperService, useValue: { buildV3GetQueryFromQueryResource: (query:QueryResource) => ({ filters: query.filters }) } },
      ],
    });
    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    hal.registerResource('QueryFilter', { cls: QueryFilterResource });
    hal.registerResource('QueryFilterInstance', { attrTypes: { filter: 'QueryFilter' } });
  });

  function workPackage(id:number) {
    workPackageChanges.set(String(id), new Subject());
    relationChanges.set(String(id), new Subject());
    return hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      _links: {
        self: { href: `/api/v3/work_packages/${id}` },
        project: { href: '/api/v3/projects/1' },
      },
    });
  }

  function group(name:string):GroupDescriptor {
    return { name, id: name, type: 'WorkPackageFormRelationQueryGroup', relationType: 'blocks', isolated: true, members: [] };
  }

  function query(projectFilter = false) {
    return hal.createHalResourceOfClass(QueryResource, {
      _type: 'Query',
      filters: projectFilter ? [{ _links: { filter: { href: '/api/v3/queries/filters/project' } }, values: ['1'] }] : [],
    });
  }

  async function mount(kind:'children'|'related', heading?:GroupDescriptor, initialQuery = query()) {
    const fixture = TestBed.createComponent<WorkPackageChildrenQueryComponent|WorkPackageRelationQueryComponent>(
      kind === 'children' ? WorkPackageChildrenQueryComponent : WorkPackageRelationQueryComponent,
    );
    const wp = workPackage(1);
    fixture.componentRef.setInput('workPackage', wp);
    fixture.componentRef.setInput('query', initialQuery);
    fixture.componentRef.setInput('group', heading);
    await fixture.whenStable();

    const table = fixture.debugElement.children.find((child) => child.componentInstance instanceof EmbeddedTableStubComponent)!
      .componentInstance as EmbeddedTableStubComponent;
    return { fixture, table, wp };
  }

  it('labels the table by the group heading', async () => {
    await mount('children', group('Children'));

    const heading = screen.getByRole('heading', { name: 'Children' });
    expect(heading.id).toMatch(/^wp-query-group-heading-/);
    expect(screen.getByRole('table', { name: 'Children' })).toHaveAttribute('aria-labelledby', heading.id);
  });

  it('leaves the table unlabeled without a group', async () => {
    await mount('children');

    expect(screen.queryByRole('heading')).not.toBeInTheDocument();
    expect(screen.getByRole('table')).not.toHaveAttribute('aria-labelledby');
  });

  it('hides a related table when its loaded query loses the project filter and keeps it hidden on replacement', async () => {
    const { fixture, table } = await mount('related', group('Blocks'), query(true));
    expect(screen.getByRole('table', { name: 'Blocks' })).toBeInTheDocument();

    let resolveQuery!:(query:QueryResource) => void;
    table.loadedQuery = new Promise((resolve) => { resolveQuery = resolve; });
    fireEvent.click(screen.getByRole('button', { name: 'Load query' }));
    await fixture.whenStable();
    expect(screen.getByRole('table', { name: 'Blocks' })).toBeInTheDocument();

    resolveQuery(query());
    await table.loadedQuery;
    await fixture.whenStable();
    expect(screen.queryByRole('table')).not.toBeInTheDocument();

    fixture.componentRef.setInput('query', query(true));
    await fixture.whenStable();
    expect(screen.queryByRole('table')).not.toBeInTheDocument();
  });

  it('publishes child associations, refreshes only for the current work package, and unsubscribes on destroy', async () => {
    const { fixture, table, wp } = await mount('children');
    const events = vi.spyOn(TestBed.inject(HalEventsService), 'push');
    const inlineCreate = fixture.debugElement.injector.get(WorkPackageInlineCreateService);

    inlineCreate.newInlineWorkPackageCreated.next('3');
    expect(events).toHaveBeenCalledWith(wp, expect.objectContaining({ eventType: 'association', relatedWorkPackage: '3', relationType: 'child' }));

    const previous = workPackageChanges.get('1')!;
    previous.next(wp);
    expect(table.loadQuery).toHaveBeenCalledOnce();
    expect(updateCounter).toHaveBeenCalledWith(wp);

    const replacement = workPackage(2);
    fixture.componentRef.setInput('workPackage', replacement);
    await fixture.whenStable();
    expect(inlineCreate.referenceTarget).toBe(replacement);
    expect(previous.observed).toBe(false);

    const current = workPackageChanges.get('2')!;
    current.next(replacement);
    expect(table.loadQuery).toHaveBeenCalledTimes(2);
    expect(updateCounter).toHaveBeenLastCalledWith(replacement);

    fixture.destroy();
    expect(current.observed).toBe(false);
    expect(inlineCreate.newInlineWorkPackageCreated.observed).toBe(false);
  });
});

describe('children query input contracts', () => {
  function firstChange<T>(value:T) {
    return new SimpleChange<T>(undefined as T, value, true);
  }

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

  it('passes plain request parameters through unchanged', () => {
    const requestParams = {
      filters: JSON.stringify([{ parent: { operator: '=', values: ['42'] } }]),
      'columns[]': ['id', 'type', 'subject', 'status'],
      showHierarchies: false,
    };
    const childQuery = TestBed.runInInjectionContext(() => new WorkPackageChildrenQueryComponent());
    childQuery.workPackage = resource;
    childQuery.query = requestParams;
    childQuery.ngOnChanges({
      workPackage: firstChange(resource),
      query: firstChange(childQuery.query),
    });

    expect(childQuery.queryProps).toBe(requestParams);
  });

  it('serializes a HAL query while retaining contextual request options', () => {
    const childQuery = TestBed.runInInjectionContext(() => new WorkPackageChildrenQueryComponent());
    childQuery.workPackage = resource;
    childQuery.query = factory.createHalResourceOfType<QueryResource>('Query', {
      columns: [], filters: [], sortBy: [], timestamps: [], showHierarchies: true,
    });
    childQuery.ngOnChanges({
      workPackage: firstChange(resource),
      query: firstChange(childQuery.query),
    });

    expect(childQuery.queryProps).toMatchObject({ valid_subset: true, showHierarchies: true, filters: '[]' });
    expect(TestBed.inject(WorkPackageInlineCreateService).referenceTarget).toBe(resource);
  });
});
