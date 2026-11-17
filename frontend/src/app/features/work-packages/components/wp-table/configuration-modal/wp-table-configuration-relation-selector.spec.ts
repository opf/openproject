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
import { TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { fireEvent, within } from '@testing-library/dom';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { initializeHalResourceConfig } from 'core-app/features/hal/services/hal-resource.config';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { firstValueFrom, Subject } from 'rxjs';
import { WpTableConfigurationRelationSelectorComponent } from './wp-table-configuration-relation-selector';

describe('WpTableConfigurationRelationSelectorComponent', () => {
  it('renders available relation types after filters load and replaces only the relation filter', async () => {
    const ready = new Subject<void>();
    const availableFilters:QueryFilterResource[] = [];
    const operators:QueryOperatorResource[] = [];
    const current:QueryFilterInstanceResource[] = [];
    const add = vi.fn<WorkPackageViewFiltersService['add']>((filter) => { current.push(filter); });
    const remove = vi.fn<WorkPackageViewFiltersService['remove']>((...filters) => {
      filters.forEach((filter) => {
        const index = current.findIndex((instance) => instance === filter);
        if (index !== -1) current.splice(index, 1);
      });
    });
    const instantiate = vi.fn<WorkPackageViewFiltersService['instantiate']>((filter) => {
      const instance = TestBed.inject(HalResourceService).createHalResourceOfClass(QueryFilterInstanceResource, {
        _type: 'QueryFilterInstance',
        _links: { filter: typeof filter === 'string' ? { href: filter } : filter.$source._links.self },
      });
      return instance;
    });

    await TestBed.configureTestingModule({
      imports: [FormsModule],
      declarations: [WpTableConfigurationRelationSelectorComponent],
      providers: [
        provideHttpClient(),
        { provide: ConfigurationService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key.split('.').at(-1) } },
        { provide: SchemaCacheService, useValue: { of: () => ({ availableOperators: operators }) } },
        {
          provide: WorkPackageViewFiltersService,
          useValue: {
            onReady: () => firstValueFrom(ready),
            availableFilters,
            current,
            instantiate,
            add,
            remove,
          },
        },
      ],
    }).compileComponents();

    const resources = TestBed.inject(HalResourceService);
    initializeHalResourceConfig(resources)();
    const filterFor = (id:string) => resources.createHalResourceOfClass(QueryFilterResource, {
      id,
      _links: { self: { href: `/api/v3/queries/filters/${id}` } },
    });
    const parent = filterFor('parent');
    const blocks = filterFor('blocks');
    const status = filterFor('status');
    const operator = resources.createHalResourceOfClass(QueryOperatorResource, {
      id: '=',
      _links: { self: { href: '/api/v3/queries/operators/=' } },
    });
    availableFilters.push(parent, blocks, status);
    operators.push(operator);
    const existingRelation = instantiate(blocks);
    const existingStatus = instantiate(status);
    current.push(existingRelation, existingStatus);
    instantiate.mockClear();

    const fixture = TestBed.createComponent(WpTableConfigurationRelationSelectorComponent);
    await fixture.whenStable();
    const select = within(fixture.nativeElement).getByRole('combobox');
    expect(within(select).queryAllByRole('option')).toHaveLength(0);

    ready.next();
    ready.complete();
    await Promise.resolve();
    await fixture.whenStable();
    const children = within(select).getByRole<HTMLOptionElement>('option', { name: 'children' });
    expect(select).toHaveDisplayValue('blocked');
    expect(within(select).queryByRole('option', { name: 'status' })).not.toBeInTheDocument();

    fireEvent.change(select, { target: { value: children.value } });
    await fixture.whenStable();

    expect(select).toHaveDisplayValue('children');
    expect(instantiate).toHaveBeenLastCalledWith(parent);
    expect(current).toContain(existingStatus);
    expect(current.map((filter) => filter.id)).toEqual(['status', 'parent']);
    expect(current[1].operator).toBe(operator);
    expect(current[1].values).toEqual([{ href: '/api/v3/work_packages/{id}' }]);
  });
});
