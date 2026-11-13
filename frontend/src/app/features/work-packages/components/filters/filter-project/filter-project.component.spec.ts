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

import { TestBed } from '@angular/core/testing';
import type { Mock } from 'vitest';
import { Observable, of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { FilterProjectComponent } from './filter-project.component';

describe('FilterProjectComponent', () => {
  let component:FilterProjectComponent;
  let listProjects:Mock<(params:unknown) => Observable<{ elements:unknown[] }>>;

  beforeEach(() => {
    listProjects = vi.fn(() => of({ elements: [] }));
    TestBed.configureTestingModule({
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: ApiV3Service, useValue: { projects: { list: listProjects } } },
        { provide: CurrentProjectService, useValue: {} },
      ],
    });
    component = TestBed.runInInjectionContext(() => new FilterProjectComponent());
    component.filter = { values: [] } as unknown as QueryFilterInstanceResource;
  });

  it('looks up the chosen projects by ID, skipping those without one', async () => {
    await component.onChange([{ id: 4 }, { href: '/api/v3/projects/5' }, { name: 'Unresolved' }]);

    expect(listProjects).toHaveBeenCalledExactlyOnceWith({ filters: [['id', '=', ['4', '5']]] });
  });
});
