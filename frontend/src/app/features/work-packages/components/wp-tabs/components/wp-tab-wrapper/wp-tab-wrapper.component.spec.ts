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
import { Component, Input } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { BehaviorSubject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageTabsService } from '../../services/wp-tabs/wp-tabs.service';
import { WpTabWrapperComponent } from './wp-tab-wrapper.component';

@Component({ template: '{{ workPackage.subject }}' })
class TabComponent {
  @Input() workPackage:Pick<WorkPackageResource, 'id'|'subject'>;
}

describe('WpTabWrapperComponent dynamic tab', () => {
  it('renders the selected tab and forwards replacement work packages', async () => {
    const resource = new BehaviorSubject({ id: '42', subject: 'First subject' });
    TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [WpTabWrapperComponent],
      providers: [
        { provide: I18nService, useValue: {} },
        { provide: ApiV3Service, useValue: { work_packages: { id: () => ({ requireAndStream: () => resource }) } } },
        { provide: WorkPackageTabsService, useValue: { getTab: () => ({ id: 'test', name: 'Test', component: TabComponent }) } },
      ],
    });
    const fixture = TestBed.createComponent(WpTabWrapperComponent);
    fixture.componentRef.setInput('workPackageId', '42');
    fixture.componentRef.setInput('tabIdentifier', 'test');
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('First subject');
    resource.next({ id: '42', subject: 'Replacement subject' });
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Replacement subject');
  });

  it('renders no child when the selected tab is unavailable', async () => {
    const resource = new BehaviorSubject({ id: '42', subject: 'First subject' });
    TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [WpTabWrapperComponent],
      providers: [
        { provide: I18nService, useValue: {} },
        { provide: ApiV3Service, useValue: { work_packages: { id: () => ({ requireAndStream: () => resource }) } } },
        { provide: WorkPackageTabsService, useValue: { getTab: () => undefined } },
      ],
    });
    const fixture = TestBed.createComponent(WpTabWrapperComponent);
    fixture.componentRef.setInput('workPackageId', '42');
    fixture.componentRef.setInput('tabIdentifier', 'missing');
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).textContent?.trim()).toBe('');
  });
});
