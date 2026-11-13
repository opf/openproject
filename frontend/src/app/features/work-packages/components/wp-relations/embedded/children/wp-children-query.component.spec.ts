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

import { AsyncPipe, NgClass } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { ChangeDetectorRef, Component, Input, SimpleChange, inject, input, output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, screen } from '@testing-library/dom';
import { multiInput } from '@openproject/reactivestates';
import { EMPTY, of, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { initializeHalResourceConfig } from 'core-app/features/hal/services/hal-resource.config';
import { buildQuery, FakeDragAndDropService, harnessProviders } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { buildWorkPackage } from 'core-app/features/work-packages/components/wp-fast-table/testing/work-package-fixture';
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { WorkPackageEmbeddedTableComponent } from 'core-app/features/work-packages/components/wp-table/embedded/wp-embedded-table.component';
import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewIncludeSubprojectsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { WorkPackageViewPaginationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { WorkPackageInlineCreateService } from 'core-app/features/work-packages/components/wp-inline-create/wp-inline-create.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { RelationsStateValue, WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { OpTableActionFactory } from 'core-app/features/work-packages/components/wp-table/table-actions/table-action';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { GroupDescriptor } from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';
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
  @Input() queryProps:object;
  readonly initialLoadingIndicator = input.required<boolean>();
  readonly tableActions = input.required<OpTableActionFactory[]>();
  // eslint-disable-next-line @angular-eslint/no-output-on-prefix
  readonly onQueryLoaded = output<QueryResource>();

  loadedQuery:Promise<QueryResource>;

  loadingIndicator:Promise<unknown>;

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
  const requireRelations = vi.fn<WorkPackageRelationsService['require']>();
  const findRelation = vi.fn<WorkPackageRelationsService['find']>();
  const removeRelation = vi.fn<WorkPackageRelationsService['removeRelation']>();

  beforeEach(() => {
    vi.resetAllMocks();
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
        {
          provide: WorkPackageRelationsService,
          useValue: { observe: (id:string) => relationChanges.get(id), updateCounter, require: requireRelations, find: findRelation, removeRelation },
        },
        { provide: WorkPackageNotificationService, useValue: {} },
        { provide: UrlParamsHelperService, useValue: { buildV3GetQueryFromQueryResource: (query:QueryResource) => ({ filters: query.filters }) } },
      ],
    });
    hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    hal.registerResource('QueryFilter', { cls: QueryFilterResource });
    hal.registerResource('QueryFilterInstance', { attrTypes: { filter: 'QueryFilter' } });
  });

  function workPackage(id:number, canChangeParent = false) {
    workPackageChanges.set(String(id), new Subject());
    relationChanges.set(String(id), new Subject());
    return hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      _links: {
        self: { href: `/api/v3/work_packages/${id}` },
        project: { href: '/api/v3/projects/1' },
        ...(canChangeParent ? { changeParent: { href: `/api/v3/work_packages/${id}`, method: 'patch' } } : {}),
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

  it('unlinks the original relation after the selected work package and group change', async () => {
    const { fixture, table, wp } = await mount('related', group('Blocks'));
    const related = workPackage(2, true);
    const record = hal.createHalResourceOfClass(RelationResource, { _type: 'Relation', type: 'blocks', reverseType: 'blocked' });
    record.from = wp;
    record.to = related;
    let resolveRelations!:(relations:RelationsStateValue) => void;
    requireRelations.mockReturnValue(new Promise((resolve) => { resolveRelations = resolve; }));
    findRelation.mockReturnValue(record);
    removeRelation.mockResolvedValue(undefined);

    const action = table.tableActions()[0];
    expect(action(fixture.debugElement.injector, wp).buildElement()).toBeNull();
    const root = fixture.nativeElement as HTMLElement;
    root.append(action(fixture.debugElement.injector, related).buildElement()!);
    fireEvent.click(screen.getByRole('link', { name: 'js.relation_buttons.remove' }));
    expect(requireRelations).toHaveBeenCalledWith('2');

    fixture.componentRef.setInput('workPackage', workPackage(3));
    fixture.componentRef.setInput('group', { ...group('Duplicates'), relationType: 'duplicates' });
    await fixture.whenStable();
    resolveRelations({});
    await table.loadingIndicator;

    expect(findRelation).toHaveBeenCalledWith(related, wp, 'blocks');
    expect(removeRelation).toHaveBeenCalledWith(record);
    expect(table.loadQuery).not.toHaveBeenCalled();
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

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-table',
  imports: [AsyncPipe],
  template: `
    <table [attr.aria-labelledby]="configuration().labelledBy">
      <tbody>
        @for (workPackage of (results | async)?.elements; track workPackage.id) {
          <tr><td>{{ workPackage.subject }}</td></tr>
        }
      </tbody>
    </table>
  `,
})
class TableResultsStubComponent {
  readonly results = inject(IsolatedQuerySpace).results.values$();
  readonly projectIdentifier = input<string>();
  readonly configuration = input.required<WorkPackageTableConfiguration>();
  readonly itemClicked = output<{ workPackageId:string; double:boolean }>();
  readonly stateLinkClicked = output<{ workPackageId:string; requestedState:'show'|'split' }>();
}

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-grid',
  template: '',
})
class GridStubComponent {
  readonly configuration = input.required<WorkPackageTableConfiguration>();
  readonly itemClicked = output<{ workPackageId:string; double:boolean }>();
  readonly stateLinkClicked = output<{ workPackageId:string; requestedState:'show'|'split' }>();
}

@Component({ selector: 'op-filter-container', template: '' })
class FiltersStubComponent {
  readonly showFilterButton = input.required<boolean>();
  readonly filterButtonText = input.required<string>();
}

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-table-pagination',
  template: '',
})
class PaginationStubComponent {
  readonly hideForSinglePageResults = input.required<boolean>();
}

describe('visible embedded relation queries', () => {
  it.each(['children', 'related'] as const)('loads only the bound %s query when a replacement cache value replays', async (kind) => {
    const cachedWorkPackages = multiInput<WorkPackageResource>();
    const cachedRelations = multiInput<RelationsStateValue>();
    const initialParams = { filters: 'initial-work-package' };
    const replacementParams = { filters: 'replacement-work-package' };
    const find = vi.fn<ApiV3Service['queries']['find']>((params) => {
      const result = buildQuery(['subject'], null, false, false);
      const subject = params === initialParams ? 'Initial result' : 'Replacement result';
      result.results = { total: 1, count: 1, elements: [buildWorkPackage({ id: '42', subject })] } as WorkPackageCollectionResource;
      return of(result);
    });

    TestBed.configureTestingModule({
      declarations: [WorkPackageChildrenQueryComponent, WorkPackageRelationQueryComponent, WorkPackageEmbeddedTableComponent],
      imports: [NgClass, TableResultsStubComponent, GridStubComponent, FiltersStubComponent, PaginationStubComponent],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        provideHttpClient(),
        provideHttpClientTesting(),
        HalResourceService,
        StaticQueriesService,
        WorkPackagesListChecksumService,
        WorkPackageViewDisplayRepresentationService,
        WorkPackageViewFiltersService,
        WorkPackageViewIncludeSubprojectsService,
        WorkPackageViewPaginationService,
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { updates$: () => EMPTY } },
        { provide: PaginationService, useValue: {} },
        { provide: OpModalService, useValue: {} },
        { provide: LoadingIndicatorService, useValue: { indicator: () => ({ promise: undefined }) } },
        { provide: CurrentUserService, useValue: {} },
        { provide: WorkPackageRelationsHierarchyService, useValue: {} },
        {
          provide: ApiV3Service,
          useValue: {
            work_packages: { id: (wp:WorkPackageResource) => ({ observe: () => cachedWorkPackages.get(wp.id!).values$() }) },
            queries: { find },
          },
        },
        {
          provide: WorkPackageRelationsService,
          useValue: { observe: (id:string) => cachedRelations.get(id).values$(), updateCounter: vi.fn() },
        },
        { provide: UrlParamsHelperService, useValue: {} },
        {
          provide: WorkPackageStatesInitializationService,
          deps: [IsolatedQuerySpace, WorkPackageViewTimelineService],
          useFactory: (querySpace:IsolatedQuerySpace, timeline:WorkPackageViewTimelineService) => ({
            clearStates: () => querySpace.initialized.clear('Reset'),
            initializeFromQuery: (query:QueryResource) => timeline.initialize(query, query.results),
            updateQuerySpace: (query:QueryResource) => {
              querySpace.query.putValue(query);
              querySpace.results.putValue(query.results);
              querySpace.initialized.putValue(null);
            },
          }),
        },
      ],
    });

    const hal = TestBed.inject(HalResourceService);
    hal.registerResource('WorkPackage', { cls: WorkPackageResource });
    const workPackage = (id:string) => hal.createHalResource<WorkPackageResource>({
      _type: 'WorkPackage',
      _links: {
        self: { href: `/api/v3/work_packages/${id}` },
        project: { href: '/api/v3/projects/1' },
      },
    });
    const original = workPackage('1');
    const replacement = workPackage('2');
    const record = hal.createHalResourceOfClass(RelationResource, { _type: 'Relation' });
    cachedWorkPackages.get('2').putValue(replacement);
    cachedRelations.get('2').putValue({ '1': record });

    const fixture = TestBed.createComponent<WorkPackageChildrenQueryComponent|WorkPackageRelationQueryComponent>(
      kind === 'children' ? WorkPackageChildrenQueryComponent : WorkPackageRelationQueryComponent,
    );
    const heading:GroupDescriptor = { name: 'Relations', id: 'relations', type: 'WorkPackageFormRelationQueryGroup', relationType: 'blocks', isolated: true, members: [] };
    fixture.componentRef.setInput('workPackage', original);
    fixture.componentRef.setInput('query', initialParams);
    fixture.componentRef.setInput('group', heading);
    const table = await screen.findByRole('table', { name: 'Relations' });
    expect(table).toBeVisible();
    expect(screen.getByRole('cell', { name: 'Initial result' })).toBeInTheDocument();
    expect(find.mock.calls.map(([params]) => params)).toEqual([initialParams]);

    fixture.componentRef.setInput('workPackage', replacement);
    fixture.componentRef.setInput('query', replacementParams);
    expect(await screen.findByRole('cell', { name: 'Replacement result' })).toBeInTheDocument();
    expect(screen.getByRole('table', { name: 'Relations' })).toBe(table);
    expect(find.mock.calls.map(([params]) => params)).toEqual([initialParams, replacementParams]);

    cachedWorkPackages.get('2').putValue(replacement);
    cachedRelations.get('2').putValue({ '1': record });
    await fixture.whenStable();
    expect(find.mock.calls.map(([params]) => params)).toEqual([initialParams, replacementParams, replacementParams]);
  });
});
