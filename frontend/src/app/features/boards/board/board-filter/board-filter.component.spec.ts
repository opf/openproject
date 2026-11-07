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

import { AsyncPipe } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { Component, inject } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import * as Turbo from '@hotwired/turbo';
import { screen } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { States } from 'core-app/core/states/states.service';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { Subject } from 'rxjs';
import { Board } from '../board';
import { BoardFilterComponent } from './board-filter.component';
import { BoardFiltersService } from './board-filters.service';

@Component({
  selector: 'op-filter-container',
  template: '<p>{{ (query$ | async)?.name ?? "Loading filters" }}</p>',
  imports: [AsyncPipe],
})
class FilterContainerStubComponent {
  protected readonly query$ = inject(IsolatedQuerySpace).query.values$();
}

describe('BoardFilterComponent', () => {
  let board:Board;
  let form:QueryFormResource;
  let query:QueryResource;
  let boards:Subject<Board>;
  let forms:Subject<[QueryFormResource, QueryResource]>;
  let updateStatesFromForm:ReturnType<typeof vi.fn<WorkPackageStatesInitializationService['updateStatesFromForm']>>;

  beforeEach(async () => {
    boards = new Subject<Board>();
    forms = new Subject<[QueryFormResource, QueryResource]>();
    updateStatesFromForm = vi.fn<WorkPackageStatesInitializationService['updateStatesFromForm']>();
    await TestBed.configureTestingModule({
      declarations: [BoardFilterComponent],
      imports: [FilterContainerStubComponent],
      providers: [
        provideHttpClient(),
        BoardFiltersService,
        IsolatedQuerySpace,
        States,
        { provide: PaginationService, useValue: {} },
        WorkPackageViewFiltersService,
        { provide: CurrentProjectService, useValue: { id: '42' } },
        { provide: WorkPackageStatesInitializationService, useValue: { updateStatesFromForm } },
      ],
    }).compileComponents();

    const hal = TestBed.inject(HalResourceService);
    board = new Board(hal.createHalResourceOfClass(GridResource, {
      options: {},
      widgets: [],
      _links: { self: { href: '/api/v3/grids/1' } },
    }));
    form = hal.createHalResourceOfClass(QueryFormResource, {
      _links: { self: { href: '/api/v3/queries/form' } },
    });
    query = hal.createHalResourceOfClass(QueryResource, {
      name: 'Board filters',
      filters: [],
      _links: { self: { href: '/api/v3/queries/1' } },
    });
  });

  it('loads a form for the initial board and publishes its query to the filter container', async () => {
    const load = vi.spyOn(TestBed.inject(ApiV3Service).queries.form, 'loadWithParams').mockReturnValue(forms);
    const fixture = TestBed.createComponent(BoardFilterComponent);
    fixture.componentRef.setInput('board$', boards);
    await fixture.whenStable();

    expect(screen.getByText('Loading filters')).toBeVisible();
    expect(load).not.toHaveBeenCalled();

    boards.next(board);
    expect(load).toHaveBeenCalledExactlyOnceWith({ filters: '[]' }, undefined, '42');

    forms.next([form, query]);
    expect(await screen.findByText('Board filters')).toBeVisible();
    expect(updateStatesFromForm).toHaveBeenCalledWith(query, form);

    boards.next(board);
    expect(load).toHaveBeenCalledOnce();
  });

  it('cancels a pending query form on teardown', async () => {
    vi.spyOn(TestBed.inject(ApiV3Service).queries.form, 'loadWithParams').mockReturnValue(forms);
    const fixture = TestBed.createComponent(BoardFilterComponent);
    fixture.componentRef.setInput('board$', boards);
    await fixture.whenStable();

    boards.next(board);
    expect(forms.observed).toBe(true);
    fixture.destroy();

    expect(forms.observed).toBe(false);
    forms.next([form, query]);
    expect(updateStatesFromForm).not.toHaveBeenCalled();
  });

  it('unsubscribes if destroyed before the board loads', async () => {
    const fixture = TestBed.createComponent(BoardFilterComponent);
    fixture.componentRef.setInput('board$', boards);
    await fixture.whenStable();

    expect(boards.observed).toBe(true);
    fixture.destroy();
    expect(boards.observed).toBe(false);
  });

  it('publishes debounced filter updates and discards a pending update on teardown', async () => {
    vi.spyOn(TestBed.inject(ApiV3Service).queries.form, 'loadWithParams').mockReturnValue(forms);
    const push = vi.spyOn(Turbo.session.history, 'push').mockImplementation(() => undefined);
    const filterState = TestBed.inject(BoardFiltersService);
    const viewFilters = TestBed.inject(WorkPackageViewFiltersService);
    const fixture = TestBed.createComponent(BoardFilterComponent);
    fixture.componentRef.setInput('board$', boards);
    await fixture.whenStable();

    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'setInterval', 'clearInterval', 'Date'] });
    try {
      filterState.filters.putValue([{ status: { operator: '=', values: ['1'] } }]);
      boards.next(board);
      viewFilters.update([]);
      expect(push).not.toHaveBeenCalled();

      viewFilters.update([]);
      vi.advanceTimersByTime(250);
      expect(push).toHaveBeenCalledOnce();
      expect(push.mock.calls[0][0].searchParams.get('query_props')).toBe('[]');
      expect(filterState.current).toEqual([]);

      viewFilters.update([]);
      fixture.destroy();
      vi.advanceTimersByTime(250);
      expect(push).toHaveBeenCalledOnce();
    } finally {
      vi.useRealTimers();
      push.mockRestore();
    }
  });
});
