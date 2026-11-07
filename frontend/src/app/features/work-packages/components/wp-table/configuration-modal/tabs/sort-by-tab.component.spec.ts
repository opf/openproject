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
import { fireEvent, within } from '@testing-library/dom';
import { of, Subject } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC, QuerySortByResource } from 'core-app/features/hal/resources/query-sort-by-resource';
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
    available = [sortBy('id'), sortBy('subject'), sortBy('subject', QUERY_SORT_BY_DESC), sortBy('manualSorting')],
    ready = of(null),
  ) {
    const update = vi.fn<WorkPackageViewSortByService['update']>();
    await TestBed.configureTestingModule({
      declarations: [WpTableConfigurationSortByTabComponent],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        {
          provide: WorkPackageViewSortByService,
          useValue: {
            onReadyWithAvailable: () => ready,
            update,
            available,
            current,
          } satisfies Pick<WorkPackageViewSortByService, 'onReadyWithAvailable'|'available'|'current'|'update'>,
        },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(WpTableConfigurationSortByTabComponent);
    await fixture.whenStable();

    return { fixture, update, component: fixture.componentInstance, element: fixture.nativeElement as HTMLElement };
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
    expect(manualRadio(element)).toBeInTheDocument();
  });

  it('keeps every column and hides the manual mode when the query offers no manual sort option', async () => {
    const { component, element } = await createComponent([sortBy('subject')], [sortBy('id'), sortBy('subject')]);

    expect(component.allColumns.map((column) => column.name)).toEqual(['id', 'subject']);
    expect(component.sortingMode).toBe('automatic');
    expect(manualRadio(element)).not.toBeInTheDocument();
  });

  it('renders sorting options arriving after initial rendering', async () => {
    const ready = new Subject<null>();
    const { fixture, element } = await createComponent([sortBy('subject')], undefined, ready);
    const view = within(element);
    expect(view.queryByRole('combobox')).not.toBeInTheDocument();

    ready.next(null);
    ready.complete();
    await fixture.whenStable();

    expect(view.getAllByRole('combobox')).toHaveLength(3);
    expect(view.getAllByRole('combobox')[0]).toHaveValue('/api/v3/queries/columns/subject');
  });

  it('shows default ID sorting when switching from manual to automatic', async () => {
    const { fixture, element, component, update } = await createComponent([sortBy('manualSorting')]);
    const view = within(element);
    expect(manualRadio(element)).toBeChecked();
    expect(view.queryByRole('combobox')).not.toBeInTheDocument();

    fireEvent.click(view.getByRole('radio', { name: /sorting_mode.automatic/ }));
    await fixture.whenStable();

    expect(view.getAllByRole('combobox')[0]).toHaveValue('/api/v3/queries/columns/id');
    component.onSave();
    expect(update).toHaveBeenCalledWith([sortBy('id')]);
  });

  it('updates available criteria and saves the edited column and direction', async () => {
    const { fixture, element, component, update } = await createComponent([sortBy('id')]);
    const view = within(element);
    fireEvent.change(view.getAllByRole('combobox')[0], { target: { value: '/api/v3/queries/columns/subject' } });
    fireEvent.click(view.getAllByRole('radio', { name: 'js.label_descending' })[0]);
    await fixture.whenStable();

    expect(view.getAllByRole('combobox')[0]).toHaveValue('/api/v3/queries/columns/subject');
    expect(view.getAllByRole('radio', { name: 'js.label_descending' })[0]).toBeChecked();
    const secondCriterion = within(view.getAllByRole('combobox')[1]);
    expect(secondCriterion.queryByRole('option', { name: 'subject' })).not.toBeInTheDocument();
    expect(secondCriterion.getByRole('option', { name: 'id' })).toBeInTheDocument();
    expect(update).not.toHaveBeenCalled();
    component.onSave();
    expect(update).toHaveBeenCalledWith([sortBy('subject', QUERY_SORT_BY_DESC)]);
  });

  it('hides automatic criteria and saves manual sorting', async () => {
    const { fixture, element, component, update } = await createComponent([sortBy('subject')]);
    const view = within(element);
    fireEvent.click(view.getByRole('radio', { name: /sorting_mode.manually/ }));
    await fixture.whenStable();

    expect(manualRadio(element)).toBeChecked();
    expect(view.queryByRole('combobox')).not.toBeInTheDocument();
    component.onSave();
    expect(update).toHaveBeenCalledWith([sortBy('manualSorting')]);
  });

  it('labels each sort criterion select with its own position', async () => {
    const { element } = await createComponent([sortBy('subject')]);

    const [first, second, third] = within(element).getAllByRole('combobox');
    expect(first).toHaveAccessibleName('js.filter.sorting.criteria.one');
    expect(second).toHaveAccessibleName('js.filter.sorting.criteria.two');
    expect(third).toHaveAccessibleName('js.filter.sorting.criteria.three');
  });
});
