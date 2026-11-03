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

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DeviceService } from 'core-app/core/browser/device.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { InAppNotificationWorkPackageContentComponent } from './in-app-notification-work-package-content.component';

describe('InAppNotificationWorkPackageContentComponent', () => {
  let fixture:ComponentFixture<InAppNotificationWorkPackageContentComponent>;
  let element:HTMLElement;

  const workPackage = {
    id: '42',
    displayId: '42',
    formattedId: '#42',
    subject: 'Fix the landing gear',
    status: { id: '1', name: 'New' },
    type: { id: '3', name: 'Task' },
  } as unknown as WorkPackageResource;

  function notificationWithReason(reason:string):INotification {
    return {
      id: 17,
      reason,
      readIAN: false,
      _links: { resource: { href: '/api/v3/work_packages/42', title: workPackage.subject } },
    } as unknown as INotification;
  }

  function render(...reasons:string[]):void {
    const notifications = reasons.map((reason) => notificationWithReason(reason));
    fixture = TestBed.createComponent(InAppNotificationWorkPackageContentComponent);
    fixture.componentRef.setInput('workPackage', workPackage);
    fixture.componentRef.setInput('notification', notifications[0]);
    fixture.componentRef.setInput('aggregatedNotifications', notifications);
    fixture.detectChanges();
    element = fixture.nativeElement as HTMLElement;
  }

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [InAppNotificationWorkPackageContentComponent],
      providers: [{ provide: DeviceService, useValue: { isMobile: false } }],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    }).compileComponents();
  });

  it('renders the ID link, type and subject of the work package', () => {
    render('mentioned');

    const idLink = element.querySelector<HTMLAnchorElement>('.op-ian-item--work-package-id-link')!;
    expect(idLink.textContent).toEqual('#42');
    expect(idLink.getAttribute('href')).toEqual('/work_packages/42');
    expect(element.querySelector('op-in-app-notification-status')).not.toBeNull();
    expect(element.querySelector('.op-ian-item--work-package-type')!.textContent).toEqual('Task');
    expect(element.querySelector('.op-ian-item--work-package-subject')!.textContent).toEqual('Fix the landing gear');
  });

  it('keeps clicks on the ID link from reaching the row', () => {
    render('mentioned');
    const rowClick = vi.fn();
    element.addEventListener('click', (event) => event.preventDefault(), { capture: true });
    element.addEventListener('click', rowClick);

    element.querySelector<HTMLAnchorElement>('.op-ian-item--work-package-id-link')!
      .dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));

    expect(rowClick).not.toHaveBeenCalled();
  });

  it.each([
    [['mentioned'], 'op-in-app-notification-actors-line'],
    [['dateAlert'], 'op-in-app-notification-date-alert'],
    [['dateAlert', 'reminder'], 'op-in-app-notification-reminder-alert'],
  ])('renders the bottom line for %j with %s', (reasons, selector) => {
    render(...reasons);

    const bottomLine = element.querySelector('.op-ian-item--bottom-line')!;
    expect(bottomLine.children).toHaveLength(1);
    expect(bottomLine.firstElementChild!.tagName.toLowerCase()).toEqual(selector);
  });
});
