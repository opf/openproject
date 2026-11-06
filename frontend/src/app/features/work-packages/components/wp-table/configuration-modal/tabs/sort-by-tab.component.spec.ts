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
import { FormsModule } from '@angular/forms';
import { of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QUERY_SORT_BY_ASC, QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { WpTableConfigurationSortByTabComponent } from './sort-by-tab.component';

describe('WpTableConfigurationSortByTabComponent', () => {
  function sortBy(name:string, direction = QUERY_SORT_BY_ASC):QuerySortByResource {
    return {
      column: { name, href: `/api/v3/queries/columns/${name}` },
      direction: { href: direction },
      displayable: true,
    } as unknown as QuerySortByResource;
  }

  async function createComponent(
    current:QuerySortByResource[],
    available = [sortBy('id'), sortBy('subject'), sortBy('manualSorting')],
  ) {
    await TestBed.configureTestingModule({
      declarations: [WpTableConfigurationSortByTabComponent],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        {
          provide: WorkPackageViewSortByService,
          useValue: {
            onReadyWithAvailable: () => of(null),
            available,
            current,
          } satisfies Partial<Record<keyof WorkPackageViewSortByService, unknown>>,
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(WpTableConfigurationSortByTabComponent);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();

    return { component: fixture.componentInstance, element: fixture.nativeElement as HTMLElement };
  }

  function manualRadio(element:HTMLElement) {
    return element.querySelector('input[name="sorting_mode_switch"][value="manual"]');
  }

  it('offers ID as the first automatic criterion when the query is sorted manually', async () => {
    const { component } = await createComponent([sortBy('manualSorting')]);

    expect(component.sortingMode).toBe('manual');
    expect(component.sortObjects[0].column.href).toBe('/api/v3/queries/columns/id');
  });

  it('keeps the saved criteria for an automatically sorted query', async () => {
    const { component, element } = await createComponent([sortBy('subject')]);

    expect(component.sortingMode).toBe('automatic');
    expect(component.sortObjects[0].column.href).toBe('/api/v3/queries/columns/subject');
    expect(manualRadio(element)).not.toBeNull();
  });

  it('keeps every column and hides the manual mode when the query offers no manual sort option', async () => {
    const { component, element } = await createComponent([sortBy('subject')], [sortBy('id'), sortBy('subject')]);

    expect(component.allColumns.map((column) => column.name)).toEqual(['id', 'subject']);
    expect(component.sortingMode).toBe('automatic');
    expect(manualRadio(element)).toBeNull();
  });
});
