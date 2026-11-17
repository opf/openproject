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
import { firstValueFrom, Subject } from 'rxjs';
import { fireEvent, within } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { QueryGroupByResource } from 'core-app/features/hal/resources/query-group-by-resource';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WpTableConfigurationDisplaySettingsTabComponent } from './display-settings-tab.component';

describe('WpTableConfigurationDisplaySettingsTabComponent', () => {
  async function render(hierarchy = false) {
    const ready = new Subject<void>();
    const readyPromise = firstValueFrom(ready);
    const status = { name: 'Status', href: '/groups/status' } as QueryGroupByResource;
    const assignee = { name: 'Assignee', href: '/groups/assignee' } as QueryGroupByResource;
    const groupBy = {
      current: status,
      available: [status, assignee],
      onReady: () => readyPromise,
      update: vi.fn<WorkPackageViewGroupByService['update']>(),
    };
    const hierarchies = { isEnabled: hierarchy, setEnabled: vi.fn<WorkPackageViewHierarchiesService['setEnabled']>() };
    const sums = { current: false, setEnabled: vi.fn<WorkPackageViewSumService['setEnabled']>() };
    await TestBed.configureTestingModule({
      declarations: [WpTableConfigurationDisplaySettingsTabComponent],
      imports: [FormsModule],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageViewGroupByService, useValue: groupBy },
        { provide: WorkPackageViewHierarchiesService, useValue: hierarchies },
        { provide: WorkPackageViewSumService, useValue: sums },
      ],
    }).compileComponents();
    const fixture = TestBed.createComponent(WpTableConfigurationDisplaySettingsTabComponent);
    await fixture.whenStable();
    const view = within(fixture.nativeElement as HTMLElement);
    return { fixture, view, ready, readyPromise, groupBy, hierarchies, sums, assignee };
  }

  it('renders grouping choices when readiness resolves after the first render', async () => {
    const { fixture, view, ready, readyPromise } = await render();
    expect(view.queryByRole('option')).not.toBeInTheDocument();

    ready.next();
    await readyPromise;
    await fixture.whenStable();

    expect(view.getAllByRole('option').map((option) => option.textContent)).toEqual(['Assignee', 'Status']);
    expect(view.getByRole('combobox')).toHaveValue('/groups/status');
    expect(view.getByRole('radio', { name: /js.label_group_by/ })).toBeChecked();
  });

  it('selects grouped mode and saves the changed group and sums', async () => {
    const { fixture, view, ready, readyPromise, groupBy, hierarchies, sums, assignee } = await render(true);
    ready.next();
    await readyPromise;
    await fixture.whenStable();
    expect(view.getByRole('radio', { name: /hierarchy_mode/ })).toBeChecked();

    fireEvent.change(view.getByRole('combobox'), { target: { value: '/groups/assignee' } });
    fireEvent.click(view.getByRole('checkbox'));
    await fixture.whenStable();

    expect(view.getByRole('radio', { name: /js.label_group_by/ })).toBeChecked();
    expect(view.getByRole('combobox')).toHaveValue('/groups/assignee');
    expect(view.getByRole('checkbox')).toBeChecked();
    expect(groupBy.update).not.toHaveBeenCalled();
    fixture.componentInstance.onSave();
    expect(groupBy.update).toHaveBeenCalledWith(assignee);
    expect(hierarchies.setEnabled).toHaveBeenCalledWith(false);
    expect(sums.setEnabled).toHaveBeenCalledWith(true);
  });

  it('reveals hierarchy instructions and clears grouping when saved', async () => {
    const { fixture, view, ready, readyPromise, groupBy, hierarchies } = await render();
    ready.next();
    await readyPromise;
    await fixture.whenStable();
    expect(view.queryByText(/hierarchy_hint/)).not.toBeInTheDocument();

    fireEvent.click(view.getByRole('radio', { name: /hierarchy_mode/ }));
    await fixture.whenStable();

    expect(view.getByText(/hierarchy_hint/)).toBeInTheDocument();
    fixture.componentInstance.onSave();
    expect(groupBy.update).toHaveBeenCalledWith(null);
    expect(hierarchies.setEnabled).toHaveBeenCalledWith(true);
  });
});
