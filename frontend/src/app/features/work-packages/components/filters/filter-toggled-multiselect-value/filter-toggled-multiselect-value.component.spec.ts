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

import type { Mock } from 'vitest';
import { ChangeDetectorRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { HalResourceSortingService } from 'core-app/features/hal/services/hal-resource-sorting.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { FilterToggledMultiselectValueComponent } from './filter-toggled-multiselect-value.component';

describe('FilterToggledMultiselectValueComponent', () => {
  let component:FilterToggledMultiselectValueComponent;
  let filterChanged:Mock<(filter:QueryFilterInstanceResource) => void>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        { provide: HalResourceService, useValue: {} },
        { provide: HalResourceSortingService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
        { provide: CurrentUserService, useValue: {} },
        { provide: ChangeDetectorRef, useValue: { detectChanges: vi.fn() } },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });
    component = TestBed.runInInjectionContext(() => new FilterToggledMultiselectValueComponent());
    component.filter = { values: ['1'] } as unknown as QueryFilterInstanceResource;
    filterChanged = vi.fn();
    component.filterChanged.subscribe(filterChanged);
  });

  it('stores the chosen values', () => {
    component.setValues(['2', { href: '/api/v3/statuses/3' }]);

    expect(component.filter.values).toEqual(['2', { href: '/api/v3/statuses/3' }]);
    expect(filterChanged).toHaveBeenCalledExactlyOnceWith(component.filter);
  });

  it('ignores a selection holding a value without an ID or link', () => {
    component.setValues(['2', { name: 'Unresolved' }]);

    expect(component.filter.values).toEqual(['1']);
    expect(filterChanged).not.toHaveBeenCalled();
  });
});
