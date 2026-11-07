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
import { ApplicationRef, Component, ComponentRef, createComponent, EnvironmentInjector, inject, input, output } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, within } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { buildQuery, FakeDragAndDropService, harnessProviders } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { buildWorkPackage } from 'core-app/features/work-packages/components/wp-fast-table/testing/work-package-fixture';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { nextTask } from 'core-common/testing/timing';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { EMPTY, Subject } from 'rxjs';
import { EmbeddedTablesMacroComponent } from './embedded-tables-macro.component';
import { WorkPackageEmbeddedTableEntryComponent } from './wp-embedded-table-entry.component';
import { WorkPackageEmbeddedTableComponent } from './wp-embedded-table.component';
import { WorkPackageTableConfiguration } from '../wp-table-configuration';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-table',
  imports: [AsyncPipe],
  template: `
    <div role="table" aria-label="Embedded work packages">
      @for (workPackage of (results | async)?.elements; track workPackage.id) {
        <div>{{ workPackage.subject }}</div>
      }
      <button (click)="stateLinkClicked.emit({ workPackageId: '42', requestedState: 'show' })">Open work package</button>
      @if (configuration().actionsColumnEnabled) {
        <button>Actions</button>
      }
    </div>
  `,
})
class TableStubComponent {
  results = inject(IsolatedQuerySpace).results.values$();
  projectIdentifier = input<string>();
  configuration = input.required<WorkPackageTableConfiguration>();
  itemClicked = output<{ workPackageId:string; double:boolean }>();
  stateLinkClicked = output<{ workPackageId:string; requestedState:'show'|'split' }>();
}

// eslint-disable-next-line @angular-eslint/component-selector
@Component({ selector: 'wp-grid', template: '<div>Work package cards</div>' })
class GridStubComponent {
  configuration = input.required<WorkPackageTableConfiguration>();
  itemClicked = output<{ workPackageId:string; double:boolean }>();
  stateLinkClicked = output<{ workPackageId:string; requestedState:'show'|'split' }>();
}

@Component({ selector: 'op-filter-container', template: '<button>{{ filterButtonText() }}</button>' })
class FiltersStubComponent {
  showFilterButton = input.required<boolean>();
  filterButtonText = input.required<string>();
}

// eslint-disable-next-line @angular-eslint/component-selector
@Component({ selector: 'wp-table-pagination', template: '<nav aria-label="Pagination"></nav>' })
class PaginationStubComponent {
  hideForSinglePageResults = input.required<boolean>();
}

describe('embedded work package table', () => {
  let requests:Subject<QueryResource>[];
  const goCurrentShowState = vi.fn<KeepTabService['goCurrentShowState']>();
  const find = vi.fn<ApiV3Service['queries']['find']>();
  let refs:ComponentRef<WorkPackageEmbeddedTableEntryComponent>[];

  beforeEach(async () => {
    refs = [];
    requests = [];
    goCurrentShowState.mockClear();
    find.mockClear().mockImplementation(() => {
      const request = new Subject<QueryResource>();
      requests.push(request);
      return request;
    });
    await TestBed.configureTestingModule({
      imports: [NgClass, TableStubComponent, GridStubComponent, FiltersStubComponent, PaginationStubComponent],
      declarations: [EmbeddedTablesMacroComponent, WorkPackageEmbeddedTableEntryComponent, WorkPackageEmbeddedTableComponent],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        StaticQueriesService,
        { provide: CurrentProjectService, useValue: { identifier: 'project' } },
        { provide: WeekdayService, useValue: {} },
        { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => EMPTY } },
        { provide: ApiV3Service, useValue: { queries: { find } } },
        { provide: PaginationService, useValue: {} },
        { provide: OpModalService, useValue: {} },
        { provide: KeepTabService, useValue: { goCurrentShowState } },
        { provide: LoadingIndicatorService, useValue: { indicator: () => ({ promise: undefined }) } },
      ],
    })
      .overrideComponent(WorkPackageEmbeddedTableEntryComponent, {
        add: {
          providers: [
            { provide: WorkPackagesListService, useValue: {} },
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
        },
      })
      .compileComponents();
  });

  afterEach(() => {
    refs.forEach((ref) => {
      ref.destroy();
      (ref.location.nativeElement as HTMLElement).remove();
    });
  });

  function query(timeline = false, subject?:string) {
    const result = buildQuery(['subject'], null, false, timeline);
    result.results = { total: 2, count: 1, elements: [buildWorkPackage({ id: '42', subject })] } as WorkPackageCollectionResource;
    return result;
  }

  function respond(index:number, result = query()) {
    requests[index].next(result);
    requests[index].complete();
  }

  it('forwards macro inputs, renders a loaded table and reloads when query props change', async () => {
    const fixture = TestBed.createComponent(EmbeddedTablesMacroComponent);
    fixture.componentRef.setInput('queryProps', { page: 2 });
    const page = within(fixture.nativeElement);
    await fixture.whenStable();
    const embedded = fixture.debugElement.query(By.directive(WorkPackageEmbeddedTableComponent))
      .injector.get(WorkPackageEmbeddedTableComponent);
    const loaded = vi.fn<(result:QueryResource) => void>();
    const failed = vi.fn<(error:unknown) => void>();
    embedded.onQueryLoaded.subscribe(loaded);
    embedded.onError.subscribe(failed);

    expect(find).toHaveBeenCalledWith({ page: 2 }, undefined, 'project');
    expect(page.queryByRole('table')).not.toBeInTheDocument();
    const initialQuery = query();
    respond(0, initialQuery);
    const table = await page.findByRole('table', { name: 'Embedded work packages' });
    expect(loaded).toHaveBeenCalledExactlyOnceWith(initialQuery);
    expect(failed).not.toHaveBeenCalled();
    expect(table).toBeVisible();
    expect(within(table).queryByRole('button', { name: 'Actions' })).not.toBeInTheDocument();
    expect(page.getByRole('navigation', { name: 'Pagination' })).toBeVisible();

    fireEvent.click(within(table).getByRole('button', { name: 'Open work package' }));
    expect(goCurrentShowState).toHaveBeenCalledWith('42');

    fixture.componentRef.setInput('queryProps', { page: 3 });
    await fixture.whenStable();
    expect(find).toHaveBeenLastCalledWith({ page: 3 }, undefined, 'project');
    const error = new Error('Request failed');
    requests[1].error(error);
    expect(await page.findByText('js.error.embedded_table_loading')).toBeVisible();
    expect(loaded).toHaveBeenCalledTimes(1);
    expect(failed).toHaveBeenCalledExactlyOnceWith(error);

    void embedded.loadQuery();
    await fixture.whenStable();
    expect(page.queryByText('js.error.embedded_table_loading')).not.toBeInTheDocument();
    const retryQuery = query();
    respond(2, retryQuery);
    await nextTask();
    await fixture.whenStable();
    expect(loaded).toHaveBeenCalledTimes(2);
    expect(loaded).toHaveBeenLastCalledWith(retryQuery);
    expect(failed).toHaveBeenCalledTimes(1);
    expect(table).toBeVisible();
  });

  it('reads the entry dataset and renders a cached timeline query without compact styling', async () => {
    const app = TestBed.inject(ApplicationRef);
    const host = document.createElement('div');
    host.dataset.queryProps = '{"page":2}';
    host.dataset.configuration = '{"compactTableStyle":true,"withFilters":true,"filterButtonText":"Filter embedded results"}';
    document.body.append(host);
    const ref = createComponent(WorkPackageEmbeddedTableEntryComponent, {
      hostElement: host,
      environmentInjector: TestBed.inject(EnvironmentInjector),
    });
    refs.push(ref);
    expect(ref.instance.queryProps).toEqual({ page: 2 });
    ref.injector.get(IsolatedQuerySpace).query.putValue(query(true));
    app.attachView(ref.hostView);
    await app.whenStable();
    expect(find).not.toHaveBeenCalled();

    const page = within(host);
    const table = await page.findByRole('table', { name: 'Embedded work packages' });
    expect(table).toBeVisible();
    expect(table.closest('.work-packages-embedded-view--container')).not.toHaveClass('-compact-tables');
    expect(page.getByRole('button', { name: 'Filter embedded results' })).toBeVisible();
  });

  it.each([
    { outcome: 'succeeds', settle: (request:Subject<QueryResource>) => { request.next(query(false, 'Obsolete result')); request.complete(); } },
    { outcome: 'fails', settle: (request:Subject<QueryResource>) => request.error(new Error('Obsolete request')) },
  ])('keeps the replacement result if the initial request $outcome later', async ({ settle }) => {
    const fixture = TestBed.createComponent(EmbeddedTablesMacroComponent);
    const page = within(fixture.nativeElement);
    fixture.componentRef.setInput('queryProps', { page: 2 });
    await fixture.whenStable();
    const embedded = fixture.debugElement.query(By.directive(WorkPackageEmbeddedTableComponent))
      .injector.get(WorkPackageEmbeddedTableComponent);
    const loaded = vi.fn<(result:QueryResource) => void>();
    const failed = vi.fn<(error:unknown) => void>();
    embedded.onQueryLoaded.subscribe(loaded);
    embedded.onError.subscribe(failed);

    fixture.componentRef.setInput('queryProps', { page: 3 });
    await fixture.whenStable();
    const currentQuery = query(false, 'Current result');
    respond(1, currentQuery);
    expect(await page.findByText('Current result')).toBeVisible();

    settle(requests[0]);
    await nextTask();
    await fixture.whenStable();
    expect(page.queryByText('js.error.embedded_table_loading')).not.toBeInTheDocument();
    expect(page.queryByText('Obsolete result')).not.toBeInTheDocument();
    expect(page.getByText('Current result')).toBeVisible();
    expect(loaded).toHaveBeenCalledExactlyOnceWith(currentQuery);
    expect(failed).not.toHaveBeenCalled();
  });
});
