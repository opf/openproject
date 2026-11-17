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
import { Component, Input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, within } from '@testing-library/dom';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { buildWorkPackage } from 'core-app/features/work-packages/components/wp-fast-table/testing/work-package-fixture';
import { WorkPackageTabsService } from 'core-app/features/work-packages/components/wp-tabs/services/wp-tabs/wp-tabs.service';
import { DynamicModule } from 'ng-dynamic-component';
import { Subject } from 'rxjs';
import { WpTabDefinition } from './tab';
import { WpTabWrapperComponent } from './wp-tab-wrapper.component';

@Component({
  template: '<button (click)="count = count + 1">{{ workPackage.subject }} ({{ count }})</button>',
})
class DetailsTabStubComponent {
  @Input() workPackage:WorkPackageResource;
  count = 0;
}

describe('WpTabWrapperComponent', () => {
  it('renders an asynchronously available tab and keeps its instance when the work package updates', async () => {
    const updates = new Subject<WorkPackageResource>();
    const tab:WpTabDefinition = { id: 'details', name: 'Details', component: DetailsTabStubComponent };
    const getTab = vi.fn<WorkPackageTabsService['getTab']>().mockReturnValue(tab);
    const id = vi.fn(() => ({ requireAndStream: () => updates }));
    await TestBed.configureTestingModule({
      imports: [AsyncPipe, DynamicModule, DetailsTabStubComponent],
      declarations: [WpTabWrapperComponent],
      providers: [
        { provide: ApiV3Service, useValue: { work_packages: { id } } },
        { provide: I18nService, useValue: {} },
        { provide: WorkPackageTabsService, useValue: { getTab } },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(WpTabWrapperComponent);
    fixture.componentRef.setInput('workPackageId', '42');
    fixture.componentRef.setInput('tabIdentifier', 'details');
    const wrapper = within(fixture.nativeElement);
    await fixture.whenStable();
    expect(wrapper.queryByRole('button')).not.toBeInTheDocument();

    const original = buildWorkPackage({ id: '42', subject: 'Initial subject' });
    updates.next(original);
    await fixture.whenStable();
    const tabButton = wrapper.getByRole('button', { name: 'Initial subject (0)' });
    expect(tabButton).toBeVisible();

    fireEvent.click(tabButton);
    updates.next(buildWorkPackage({ id: '42', subject: 'Updated subject' }));
    await fixture.whenStable();
    expect(wrapper.getByRole('button', { name: 'Updated subject (1)' })).toBe(tabButton);
    expect(id).toHaveBeenCalledWith('42');
    expect(getTab).toHaveBeenCalledWith('details', original);

    getTab.mockReturnValue(undefined);
    updates.next(original);
    await fixture.whenStable();
    expect(tabButton).not.toBeInTheDocument();
  });
});
