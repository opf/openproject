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

import { CommonModule } from '@angular/common';
import { provideHttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { Component, ChangeDetectionStrategy } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { NgSelectComponent } from '@ng-select/ng-select';
import { AlertIconComponent } from '@openproject/octicons-angular';
import { of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryFilterInstanceSchemaResource } from 'core-app/features/hal/resources/query-filter-instance-schema-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { SchemaAttributeObject } from 'core-app/features/hal/resources/schema-attribute-object';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { AutofocusDirective } from 'core-app/shared/directives/focus/autofocus.directive';
import { QueryFilterComponent } from './query-filter/query-filter.component';
import { QueryFiltersComponent } from './query-filters/query-filters.component';
import { WorkPackageFilterByTextInputComponent } from './quick-filter-by-text-input/quick-filter-by-text-input.component';
import { FilterStringValueComponent } from './filter-string-value/filter-string-value.component';
import { OpenprojectAutocompleterModule } from 'core-app/shared/components/autocompleter/openproject-autocompleter.module';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { FilterToggledMultiselectValueComponent } from './filter-toggled-multiselect-value/filter-toggled-multiselect-value.component';
import { FilterSearchableMultiselectValueComponent } from './filter-searchable-multiselect-value/filter-searchable-multiselect-value.component';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { WorkPackageFiltersService } from './wp-filters/wp-filters.service';

@Component({
  imports: [CommonModule, OpenprojectAutocompleterModule],
  templateUrl: './filter-toggled-multiselect-value/filter-toggled-multiselect-value.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestFilterBoundaryComponent extends FilterToggledMultiselectValueComponent {}

const searchableOptions:HalResource[] = [];

@Component({
  imports: [CommonModule, OpenprojectAutocompleterModule],
  templateUrl: './filter-searchable-multiselect-value/filter-searchable-multiselect-value.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    { provide: HalResourceNotificationService, useValue: {} },
    {
      provide: ApiV3Service,
      useValue: {
        users: { me: { path: '/api/v3/users/me' } },
        collectionFromString: () => ({
          filtered: () => ({
            get: () => of({ count: searchableOptions.length, total: searchableOptions.length, elements: searchableOptions }),
          }),
        }),
      },
    },
  ],
})
class TestSearchableFilterBoundaryComponent extends FilterSearchableMultiselectValueComponent {}

describe('Query filter template resource contracts', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule, NgSelectComponent, AlertIconComponent, TestFilterBoundaryComponent,
        TestSearchableFilterBoundaryComponent],
      declarations: [QueryFilterComponent, QueryFiltersComponent, WorkPackageFilterByTextInputComponent,
        FilterStringValueComponent, AutofocusDirective, OpIconComponent],
      providers: [
        provideHttpClient(), States, IsolatedQuerySpace, PathHelperService, HalResourceService,
        SchemaCacheService, WorkPackageViewFiltersService, WorkPackageFiltersService, UrlParamsHelperService,
        { provide: PaginationService, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: CurrentUserService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageViewBaselineService, useValue: { live$: () => of([]), isActive: () => false } },
      ],
    }).compileComponents();
    const resources = TestBed.inject(HalResourceService);
    resources.registerResource('QueryFilter', { cls: QueryFilterResource });
    resources.registerResource('QueryOperator', { cls: QueryOperatorResource });
    resources.registerResource('QueryFilterInstance', { cls: QueryFilterInstanceResource,
      attrTypes: { filter: 'QueryFilter', operator: 'QueryOperator' } });
  });

  function schema(id:string) {
    const resources = TestBed.inject(HalResourceService);
    const base = resources.createHalResourceOfClass(QueryFilterResource, {
      id, name: id, _links: { self: { href: `/api/v3/queries/filters/${id}` } },
    });
    const operators = ['=', '!*'].map((operator) => resources.createHalResourceOfClass(QueryOperatorResource, {
      name: operator, _links: { self: { href: `/api/v3/queries/operators/${operator}` } },
    }));
    const result = resources.createHalResourceOfClass(QueryFilterInstanceSchemaResource, {
      _links: { self: { href: `/api/v3/queries/filter_instance_schemas/${id}` } },
      _dependencies: [{ dependencies: {
        '/api/v3/queries/operators/=': { values: { type: '[1]String' } },
        '/api/v3/queries/operators/!*': { values: null },
      } }],
    });
    result.filter = Object.assign(new SchemaAttributeObject<QueryFilterResource>(), { allowedValues: [base] });
    result.operator = Object.assign(new SchemaAttributeObject(), { allowedValues: operators });
    TestBed.inject(States).schemas.get(result.href!).putValue(result);
    return result;
  }

  it('adds and removes real filter instances while preserving order and query values', () => {
    const filters = TestBed.inject(WorkPackageViewFiltersService);
    const first = schema('subject');
    const second = schema('description');
    filters.availableState.putValue([first, second]);
    const initial = filters.instantiate(first.allowedFilterValue);
    initial.values = ['existing'];
    filters.update([initial]);
    const fixture = TestBed.createComponent(QueryFiltersComponent);
    fixture.componentRef.setInput('filters', [initial]);
    fixture.detectChanges();
    fixture.componentInstance.onFilterAdded(second.allowedFilterValue);
    fixture.changeDetectorRef.markForCheck();
    fixture.detectChanges();
    expect(fixture.componentInstance.filters.map((filter) => filter.id)).toEqual(['subject', 'description']);
    const added = fixture.componentInstance.filters[1];
    expect(added).toBeInstanceOf(QueryFilterInstanceResource);
    added.values = ['added'];
    const rows = fixture.debugElement.queryAll(By.directive(QueryFilterComponent));
    (rows[0].componentInstance as QueryFilterComponent).removeThisFilter();
    fixture.changeDetectorRef.markForCheck();
    fixture.detectChanges();
    expect(fixture.componentInstance.filters).toEqual([added]);
    expect(fixture.componentInstance.focusElementIndex).toBe(0);
    filters.update(fixture.componentInstance.filters);
    const query = TestBed.inject(HalResourceService).createHalResourceOfClass(QueryResource, { filters: [], _links: {} });
    filters.applyToQuery(query);
    expect(query.filters[0].values).toEqual(['added']);
    expect(TestBed.inject(UrlParamsHelperService).buildV3GetFilters(query.filters)).toEqual([
      { description: { operator: '=', values: ['added'] } },
    ]);
  });

  it('preserves unresolved scalar and DTO entries with a newly selected resource', async () => {
    const resources = TestBed.inject(HalResourceService);
    const option = resources.createHalResource({ id: '8', name: 'Available', _links: { self: { href: '/api/v3/statuses/8' } } });
    const partial = { id: '9', href: '/api/v3/statuses/9' };
    const filter = schema('status').getFilter();
    filter.values = ['7', partial];
    filter.currentSchema!.values!.allowedValues = [option];
    const fixture = TestBed.createComponent(TestFilterBoundaryComponent);
    expect(fixture.componentInstance.itemTracker({ href: '', id: 0, name: 'Unassigned' })).toBe('Unassigned');
    expect(fixture.componentInstance.itemTracker({ href: '', id: '7', name: 'Later' })).toBe('7');
    expect(fixture.componentInstance.itemTracker('7')).toBeUndefined();
    fixture.componentRef.setInput('filter', filter);
    fixture.detectChanges();
    const wrapper = fixture.debugElement.query(By.directive(OpAutocompleterComponent)).componentInstance as OpAutocompleterComponent;
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(wrapper.ngSelectInstance.selectedItems).toHaveLength(2);
    });
    const raw = vi.fn();
    const changed = vi.fn();
    wrapper.change.subscribe(raw);
    fixture.componentInstance.filterChanged.subscribe(changed);
    const select = wrapper.ngSelectInstance;
    expect(select.selectedItems.map(item => item.value)).toEqual(['7', partial]);
    select.select(select.itemsList.items[0]);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    expect(filter.values).toEqual(['7', partial, option]);
    expect(filter.values).toBe(raw.mock.lastCall?.[0]);
    expect(filter.values[1]).toBe(partial);
    expect(filter.values[2]).toBe(option);
    expect(changed).toHaveBeenLastCalledWith(filter);
  });

  it('keeps a stored link reference when an option is selected in the searchable filter', async () => {
    const resources = TestBed.inject(HalResourceService);
    const option = resources.createHalResource({ id: '8', name: 'Available', _links: { self: { href: '/api/v3/work_packages/8' } } });
    searchableOptions.splice(0, searchableOptions.length, option);
    const reference = { href: '/api/v3/work_packages/{id}' };
    const filter = schema('parent').getFilter();
    filter.values = [reference];
    filter.currentSchema!.values!.allowedValues = resources.createHalResourceOfClass(CollectionResource, {
      _links: { self: { href: '/api/v3/work_packages' } },
    });
    const fixture = TestBed.createComponent(TestSearchableFilterBoundaryComponent);
    fixture.componentRef.setInput('filter', filter);
    fixture.detectChanges();
    const wrapper = fixture.debugElement.query(By.directive(OpAutocompleterComponent)).componentInstance as OpAutocompleterComponent;
    const select = wrapper.ngSelectInstance;
    await vi.waitFor(() => {
      fixture.detectChanges();
      expect(select.itemsList.items.map(item => item.value)).toContain(option);
    });
    const changed = vi.fn();
    fixture.componentInstance.filterChanged.subscribe(changed);
    select.select(select.itemsList.items.find(item => item.value === option)!);
    fixture.detectChanges();
    await fixture.whenStable();
    expect(filter.values).toEqual([reference, option]);
    expect(changed).toHaveBeenLastCalledWith(filter);
  });

  it('updates the operator and hides values for an operator that needs none', () => {
    const definition = schema('subject');
    const fixture = TestBed.createComponent(QueryFilterComponent);
    const filter = definition.getFilter();
    filter.values = ['text'];
    fixture.componentRef.setInput('filter', filter);
    fixture.detectChanges();
    const host = fixture.nativeElement as HTMLElement;
    expect(host.querySelector('op-filter-string-value')).not.toBeNull();
    const select = host.querySelector<HTMLSelectElement>('select')!;
    select.selectedIndex = 1;
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    expect(filter.operator.id).toBe('!*');
    expect(host.querySelector('op-filter-string-value')).toBeNull();
    expect(filter.values).toEqual(['text']);
  });

  it('emits the existing search instance when the text filter is cleared', async () => {
    const filters = TestBed.inject(WorkPackageViewFiltersService);
    const search = schema('search');
    filters.availableState.putValue([search]);
    const filter = search.getFilter();
    filter.values = ['text'];
    filters.update([filter]);
    const fixture = TestBed.createComponent(WorkPackageFilterByTextInputComponent);
    fixture.componentInstance.searchTerm.putValue('text');
    fixture.detectChanges();
    await fixture.whenStable();
    const removed = vi.fn();
    fixture.componentInstance.deactivateFilter.subscribe((resource) => {
      removed(resource);
    });
    const input = (fixture.nativeElement as HTMLElement).querySelector<HTMLInputElement>('input')!;
    input.value = '';
    input.dispatchEvent(new Event('input'));
    await vi.waitFor(() => expect(filters.current).toEqual([]));
    expect(removed).toHaveBeenCalledExactlyOnceWith(filter);
  });
});
