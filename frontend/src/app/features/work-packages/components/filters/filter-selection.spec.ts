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

import { ChangeDetectionStrategy, Component, CUSTOM_ELEMENTS_SCHEMA, Type } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { SelectionErrorComponent } from 'core-app/shared/components/autocompleter/selection/selection-error.component';
import { FilterProjectComponent } from './filter-project/filter-project.component';
import { FilterSearchableMultiselectValueComponent } from './filter-searchable-multiselect-value/filter-searchable-multiselect-value.component';
import { FilterToggledMultiselectValueComponent } from './filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import { createProjectFilterSelectionAdapter, createQueryFilterSelectionAdapter } from './filter-selection';

const captureMessage = vi.fn();

beforeEach(() => {
  captureMessage.mockReset();
  vi.stubGlobal('ErrorReporter', { captureMessage });
});

afterEach(() => {
  vi.unstubAllGlobals();
});

const createHal = ():HalResource => TestBed.inject(HalResourceService).createHalResource({
  id: '1', _links: { self: { href: '/api/v3/work_packages/1' } },
}, true);

describe('createQueryFilterSelectionAdapter', () => {
  let hal:HalResource;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [HalResourceService, PathHelperService] });
    hal = createHal();
  });

  it('clears the searchable profile with an empty string', () => {
    const adapter = createQueryFilterSelectionAdapter('searchable');
    adapter.bridge.accept('');
    expect(adapter.state).toEqual({ kind: 'ready', value: [] });
  });

  it('wraps a searchable scalar', () => {
    const adapter = createQueryFilterSelectionAdapter('searchable');
    adapter.bridge.accept('t');
    expect(adapter.state).toEqual({ kind: 'ready', value: ['t'] });
  });

  it('wraps a toggled scalar', () => {
    const adapter = createQueryFilterSelectionAdapter('toggled');
    adapter.bridge.accept('t');
    expect(adapter.state).toEqual({ kind: 'ready', value: ['t'] });
  });

  it('keeps the empty string as a toggled value', () => {
    const adapter = createQueryFilterSelectionAdapter('toggled');
    adapter.bridge.accept('');
    expect(adapter.state).toEqual({ kind: 'ready', value: [''] });
  });

  it.each(['searchable', 'toggled'] as const)('clears the %s profile with an empty array', (profile) => {
    const adapter = createQueryFilterSelectionAdapter(profile);
    adapter.bridge.accept([]);
    expect(adapter.state).toEqual({ kind: 'ready', value: [] });
  });

  it('accepts an array atomically and keeps its identity', () => {
    const adapter = createQueryFilterSelectionAdapter('toggled');
    const values = [hal, '7', { href: '/api/v3/work_packages/{id}' }];
    adapter.bridge.accept(values);
    expect(adapter.state.kind === 'ready' && adapter.state.value).toBe(values);
  });

  it.each(['searchable', 'toggled'] as const)('rejects an invalid array entry of the %s profile with its index', (profile) => {
    const adapter = createQueryFilterSelectionAdapter(profile);
    adapter.bridge.accept([hal, { name: 'x' }]);
    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape', index: 1 }, lastAccepted: [] });
    expect(captureMessage).toHaveBeenCalledExactlyOnceWith('selection:invalid-shape');
  });

  it('rejects nullish values', () => {
    const adapter = createQueryFilterSelectionAdapter('toggled');
    adapter.bridge.accept(null);
    expect(adapter.state.kind).toBe('invalid');
  });
});

describe('createProjectFilterSelectionAdapter', () => {
  it('decodes project DTOs to references', () => {
    const adapter = createProjectFilterSelectionAdapter();
    const dto = { id: 3, name: 'Project', href: '/api/v3/projects/3' };
    adapter.bridge.accept([dto, { id: 0 }]);
    expect(adapter.state).toEqual({ kind: 'ready', value: [dto, { id: 0 }] });
  });

  it('rejects an entry that has no resolvable identity with its index', () => {
    const adapter = createProjectFilterSelectionAdapter();
    adapter.bridge.accept([{ id: 3 }, { name: 'x' }]);
    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape', index: 1 }, lastAccepted: [] });
  });

  it('rejects a reference with an href that has no id', () => {
    const adapter = createProjectFilterSelectionAdapter();
    adapter.bridge.accept([{ href: '/api/v3/projects/' }]);
    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'invalid-shape', index: 0 }, lastAccepted: [] });
  });

  it('rejects a non-array', () => {
    const adapter = createProjectFilterSelectionAdapter();
    adapter.bridge.accept({ id: 3 });
    expect(adapter.state).toEqual({ kind: 'invalid', issue: { code: 'wrong-cardinality' }, lastAccepted: [] });
  });
});

@Component({
  imports: [SelectionErrorComponent, OpenprojectAutocompleterModule],
  templateUrl: './filter-toggled-multiselect-value/filter-toggled-multiselect-value.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestToggledComponent extends FilterToggledMultiselectValueComponent {}

@Component({
  imports: [SelectionErrorComponent, OpenprojectAutocompleterModule],
  templateUrl: './filter-searchable-multiselect-value/filter-searchable-multiselect-value.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestSearchableComponent extends FilterSearchableMultiselectValueComponent {}

@Component({
  imports: [SelectionErrorComponent],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  templateUrl: './filter-project/filter-project.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestProjectComponent extends FilterProjectComponent {}

describe('filter selection components', () => {
  const list = vi.fn();

  beforeEach(() => {
    list.mockReset();
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        HalResourceService,
        PathHelperService,
        { provide: HalResourceSortingService, useValue: { sort: (values:unknown[]) => values } },
        { provide: HalResourceNotificationService, useValue: {} },
        { provide: CurrentProjectService, useValue: { id: null } },
        { provide: CurrentUserService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        {
          provide: ApiV3Service,
          useValue: {
            users: { me: { path: '/api/v3/users/me' } },
            projects: { list },
            collectionFromString: () => ({ filtered: () => ({ get: () => of({ count: 0, total: 0, elements: [] }) }) }),
          },
        },
      ],
    });
  });

  function filterWith(values:unknown[]) {
    const filter = TestBed.inject(HalResourceService).createHalResourceOfClass(QueryFilterInstanceResource, {
      filter: { id: 'status', name: 'status', href: '/api/v3/queries/filters/status' },
    });
    filter.values = values as QueryFilterInstanceResource['values'];
    Object.defineProperties(filter, {
      currentSchema: { value: { values: { allowedValues: [], type: '[]String' } } },
    });
    return filter;
  }

  function render<T>(component:Type<T>, filter:QueryFilterInstanceResource):ComponentFixture<T> {
    const fixture = TestBed.createComponent(component);
    fixture.componentRef.setInput('filter', filter);
    fixture.detectChanges();
    return fixture;
  }

  it('clears a searchable filter with an empty string', () => {
    const filter = filterWith(['a']);
    const fixture = render(TestSearchableComponent, filter);
    fixture.componentInstance.setValues('');
    expect(filter.values).toEqual([]);
  });

  it('wraps a toggled scalar', () => {
    const filter = filterWith([]);
    const fixture = render(TestToggledComponent, filter);
    const changed = vi.fn();
    fixture.componentInstance.filterChanged.subscribe(changed);
    fixture.componentInstance.setValues('t');
    expect(filter.values).toEqual(['t']);
    expect(changed).toHaveBeenCalledExactlyOnceWith(filter);
  });

  it('ignores undefined', () => {
    const filter = filterWith(['a']);
    const fixture = render(TestToggledComponent, filter);
    const changed = vi.fn();
    fixture.componentInstance.filterChanged.subscribe(changed);
    fixture.componentInstance.setValues(undefined);
    expect(filter.values).toEqual(['a']);
    expect(changed).not.toHaveBeenCalled();
  });

  const multiselects:[string, Type<TestSearchableComponent|TestToggledComponent>][] = [
    ['searchable', TestSearchableComponent],
    ['toggled', TestToggledComponent],
  ];

  it.each(multiselects)('shows an error and leaves the %s filter untouched for an invalid entry', (_, component) => {
    const filter = filterWith(['a']);
    const fixture = render(component, filter);
    const changed = vi.fn();
    fixture.componentInstance.filterChanged.subscribe(changed);

    expect(() => fixture.componentInstance.setValues([createHal(), { name: 'x' }])).not.toThrow();
    fixture.detectChanges();

    expect(filter.values).toEqual(['a']);
    expect(changed).not.toHaveBeenCalled();
    expect(screen.getByRole('alert')).toBeTruthy();
    expect(fixture.componentInstance.selection.state).toMatchObject({ kind: 'invalid', issue: { index: 1 } });
  });

  it.each(multiselects)('resets the %s autocompleter to the current values for an invalid entry', (_, component) => {
    const filter = filterWith(['a']);
    const fixture = render(component, filter);
    const autocompleter = fixture.debugElement.query(By.directive(OpAutocompleterComponent))
      .componentInstance as OpAutocompleterComponent;

    autocompleter.changed([{ name: 'x' }]);
    fixture.detectChanges();

    expect(autocompleter.model).toEqual(['a']);
    expect(filter.values).toEqual(['a']);
  });

  it('removes the error after a valid change', () => {
    const filter = filterWith([]);
    const fixture = render(TestToggledComponent, filter);
    fixture.componentInstance.setValues([{ name: 'x' }]);
    fixture.detectChanges();
    expect(screen.queryByRole('alert')).not.toBeNull();

    fixture.componentInstance.setValues(['7']);
    fixture.detectChanges();
    expect(screen.queryByRole('alert')).toBeNull();
    expect(filter.values).toEqual(['7']);
  });

  describe('project filter', () => {
    it('resolves valid references with the projects API', async () => {
      const project = createHal();
      list.mockReturnValue(of({ elements: [project] }));
      const filter = filterWith([]);
      const fixture = render(TestProjectComponent, filter);
      const changed = vi.fn();
      fixture.componentInstance.filterChanged.subscribe(changed);

      await fixture.componentInstance.onChange([{ id: 3, name: 'P', href: '/api/v3/projects/3' }, { id: 0 }]);

      expect(list).toHaveBeenCalledExactlyOnceWith({ filters: [['id', '=', ['3', '0']]] });
      expect(filter.values).toEqual([project]);
    });

    it('clears the filter for an empty array without a request', async () => {
      const filter = filterWith(['a']);
      const fixture = render(TestProjectComponent, filter);
      await fixture.componentInstance.onChange([]);
      expect(filter.values).toEqual([]);
      expect(list).not.toHaveBeenCalled();
    });

    it('removes the error and refreshes the view after an invalid change is followed by a valid one', async () => {
      const project = createHal();
      list.mockReturnValue(of({ elements: [project] }).pipe(delay(0)));
      const filter = filterWith(['a']);
      const fixture = render(TestProjectComponent, filter);

      await fixture.componentInstance.onChange([{ name: 'x' }]);
      fixture.detectChanges();
      expect(screen.queryByRole('alert')).not.toBeNull();

      await fixture.componentInstance.onChange([{ id: 3 }]);
      await fixture.whenStable();
      fixture.detectChanges();

      expect(filter.values).toEqual([project]);
      expect(screen.queryByRole('alert')).toBeNull();
    });

    it('shows an error and never requests an unresolvable identity', async () => {
      const filter = filterWith(['a']);
      const fixture = render(TestProjectComponent, filter);

      await fixture.componentInstance.onChange([{ id: 3 }, { href: '/api/v3/projects/' }]);
      fixture.detectChanges();

      expect(list).not.toHaveBeenCalled();
      expect(filter.values).toEqual(['a']);
      expect(screen.getByRole('alert')).toBeTruthy();
    });
  });
});
