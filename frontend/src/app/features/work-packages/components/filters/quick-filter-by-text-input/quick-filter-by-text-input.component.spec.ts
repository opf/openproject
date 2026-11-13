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
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { fireEvent, within } from '@testing-library/dom';
import { Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageFilterByTextInputComponent } from './quick-filter-by-text-input.component';

describe('WorkPackageFilterByTextInputComponent', () => {
  let fixture:ComponentFixture<WorkPackageFilterByTextInputComponent>;
  let removed:ReturnType<typeof vi.fn<(filter:QueryFilterInstanceResource) => void>>;
  let pristine:Subject<QueryFilterInstanceResource[]>;
  let find:ReturnType<typeof vi.fn<WorkPackageViewFiltersService['find']>>;
  let replace:ReturnType<typeof vi.fn<WorkPackageViewFiltersService['replace']>>;
  let remove:ReturnType<typeof vi.fn<WorkPackageViewFiltersService['remove']>>;

  const view = () => within(fixture.nativeElement as HTMLElement);

  beforeEach(async () => {
    pristine = new Subject<QueryFilterInstanceResource[]>();
    find = vi.fn<WorkPackageViewFiltersService['find']>();
    replace = vi.fn<WorkPackageViewFiltersService['replace']>();
    remove = vi.fn<WorkPackageViewFiltersService['remove']>();

    await TestBed.configureTestingModule({
      declarations: [WorkPackageFilterByTextInputComponent],
      imports: [FormsModule, AsyncPipe],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: IsolatedQuerySpace, useValue: {} },
        {
          provide: WorkPackageViewFiltersService,
          useValue: {
            find, replace, remove, pristine$: () => pristine.asObservable(), textFilterId: 'search',
          } satisfies Pick<WorkPackageViewFiltersService, 'find'|'replace'|'remove'|'pristine$'|'textFilterId'>,
        },
      ],
    }).compileComponents();
    fixture = TestBed.createComponent(WorkPackageFilterByTextInputComponent);
    removed = vi.fn<(filter:QueryFilterInstanceResource) => void>();
    fixture.componentInstance.deactivateFilter.subscribe(removed);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('keeps pending quick search input, debounces commits and displays subsequent upstream updates', async () => {
    await fixture.whenStable();
    vi.useFakeTimers({ toFake: ['Date', 'setInterval', 'clearInterval'] });

    const operator = Object.assign(Object.create(QueryOperatorResource.prototype) as QueryOperatorResource, { $source: { id: '**' } });
    const filter = Object.assign(Object.create(QueryFilterInstanceResource.prototype) as QueryFilterInstanceResource, {
      values: ['upstream'],
      findOperator: () => operator,
    });
    find.mockReturnValue(filter);
    pristine.next([filter]);
    await fixture.whenStable();

    const input = view().getByRole('textbox');
    expect(input).toHaveValue('upstream');
    fireEvent.input(input, { target: { value: 'local' } });
    await vi.advanceTimersByTimeAsync(499);
    filter.values = ['late upstream'];
    pristine.next([filter]);
    await fixture.whenStable();

    expect(input).toHaveValue('local');
    expect(replace).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(1);

    expect(replace).toHaveBeenCalledTimes(1);
    const [id, update] = replace.mock.calls[0];
    expect(id).toBe('search');
    update(filter);
    expect(filter.values).toEqual(['local']);

    await vi.advanceTimersByTimeAsync(1);
    filter.values = ['settled upstream'];
    pristine.next([filter]);
    await fixture.whenStable();

    expect(input).toHaveValue('settled upstream');

    fireEvent.input(input, { target: { value: '' } });
    await vi.advanceTimersByTimeAsync(500);

    expect(remove).toHaveBeenCalledWith(filter);
    expect(removed).toHaveBeenCalledWith(filter);

    fireEvent.input(input, { target: { value: 'pending' } });
    fixture.destroy();
    await vi.advanceTimersByTimeAsync(500);

    expect(replace).toHaveBeenCalledTimes(1);
    expect(pristine.observed).toBe(false);
  });
});
