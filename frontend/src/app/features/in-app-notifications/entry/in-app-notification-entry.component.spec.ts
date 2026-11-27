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
import { NEVER, of } from 'rxjs';
import { type Mock } from 'vitest';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import { IanCenterService } from 'core-app/features/in-app-notifications/center/state/ian-center.service';
import { InAppNotificationEntryComponent } from './in-app-notification-entry.component';
import {
  InAppNotificationDocumentContentComponent,
} from './document-content/in-app-notification-document-content.component';
import {
  InAppNotificationWorkPackageContentComponent,
} from './work-package-content/in-app-notification-work-package-content.component';

describe('InAppNotificationEntryComponent', () => {
  const I18nStub = {
    t(key:string, options?:{ defaultValue?:string }) {
      return {
        'js.label_document': 'Document',
        'js.notifications.center.mark_as_read': 'Mark as read',
        'js.notifications.reasons.mentioned': 'Mentioned',
      }[key] ?? options?.defaultValue ?? key;
    },
  };

  let fixture:ComponentFixture<InAppNotificationEntryComponent>;
  let element:HTMLElement;
  let storeService:{ openSplitScreen:Mock, markAsRead:Mock, query:{ selectLoading:() => unknown } };
  let requestWorkPackage:Mock;
  let turboVisit:Mock;

  function buildNotification(resourceHref:string, resourceTitle:string):INotification {
    return {
      id: 17,
      subject: '',
      createdAt: '2026-10-15T10:00:00Z',
      updatedAt: '2026-10-15T10:00:00Z',
      reason: 'mentioned',
      readIAN: false,
      readEmail: null,
      expanded: false,
      _links: {
        resource: { href: resourceHref, title: resourceTitle },
        project: { href: '/api/v3/projects/3', title: 'Flight school' },
        actor: { href: '/api/v3/users/9', title: 'Jean Cérien' },
        activity: { href: null },
      },
    } as unknown as INotification;
  }

  const documentNotification = buildNotification('/api/v3/documents/5', 'Take-off checklist');
  const workPackageNotification = buildNotification('/api/v3/work_packages/42', 'Fix the landing gear');

  function render(notification:INotification):void {
    fixture = TestBed.createComponent(InAppNotificationEntryComponent);
    fixture.componentInstance.notification = notification;
    fixture.componentInstance.aggregatedNotifications = [notification];
    fixture.detectChanges();
    element = fixture.nativeElement as HTMLElement;
  }

  function row():HTMLElement {
    return element.querySelector('.op-ian-item--row')!;
  }

  function pressKey(target:HTMLElement, key:string):KeyboardEvent {
    const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
    target.dispatchEvent(event);
    return event;
  }

  beforeEach(async () => {
    storeService = {
      openSplitScreen: vi.fn(),
      markAsRead: vi.fn(),
      query: { selectLoading: () => of(false) },
    };
    requestWorkPackage = vi.fn(() => ({ requireAndStream: () => NEVER }));
    turboVisit = vi.fn();
    vi.stubGlobal('Turbo', { visit: turboVisit });

    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [
        InAppNotificationEntryComponent,
        InAppNotificationWorkPackageContentComponent,
        InAppNotificationDocumentContentComponent,
      ],
      providers: [
        { provide: I18nService, useValue: I18nStub },
        { provide: IanCenterService, useValue: storeService },
        { provide: ApiV3Service, useValue: { work_packages: { id: requestWorkPackage } } },
        { provide: TimezoneService, useValue: {} },
        { provide: DeviceService, useValue: { isMobile: false } },
        { provide: UrlParamsService, useValue: {} },
      ],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    }).compileComponents();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  describe('for a document notification', () => {
    beforeEach(() => render(documentNotification));

    it('renders the document label, project and reason as plain text and the project link in a new tab', () => {
      const label = element.querySelector('.op-ian-item--resource-label')!;
      expect(label.textContent).toEqual('Document');
      expect(label.closest('a')).toBeNull();
      expect(element.querySelector('.op-ian-item--work-package-id-link')).toBeNull();

      const projectLink = element.querySelector<HTMLAnchorElement>('.op-ian-item--project-link')!;
      expect(projectLink.textContent).toEqual('Flight school');
      expect(projectLink.getAttribute('href')).toEqual('/projects/3');
      expect(projectLink.target).toEqual('_blank');

      expect(element.querySelector('.op-ian-item--reason-wrapper')!.textContent.trim()).toEqual('Mentioned');
    });

    it('links only the title to the document in a new tab', () => {
      const title = element.querySelector<HTMLAnchorElement>('.op-ian-item--middle-line a')!;
      expect(title.textContent).toEqual('Take-off checklist');
      expect(title.getAttribute('href')).toEqual('/documents/5');
      expect(title.target).toEqual('_blank');
      expect(title.rel).toEqual('noopener');
    });

    it('renders no status, type, info button or loading placeholder and requests no work package', () => {
      expect(element.querySelector('op-in-app-notification-status')).toBeNull();
      expect(element.querySelector('.op-ian-item--work-package-type')).toBeNull();
      expect(element.querySelector('.icon-info1')).toBeNull();
      expect(element.querySelector('.op-ian-item--loading')).toBeNull();
      expect(element.querySelector('op-in-app-notification-actors-line')).not.toBeNull();
      expect(requestWorkPackage).not.toHaveBeenCalled();
    });

    it('renders a static row without button role or tab stop', () => {
      expect(row().hasAttribute('role')).toBe(false);
      expect(row().hasAttribute('tabindex')).toBe(false);
      expect(row().classList).toContain('op-ian-item--row_static');
    });

    it('does nothing on row click, double click, Enter or Space', () => {
      vi.useFakeTimers();

      row().click();
      row().dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));
      const enter = pressKey(row(), 'Enter');
      const space = pressKey(row(), ' ');
      vi.advanceTimersByTime(300);

      expect(storeService.openSplitScreen).not.toHaveBeenCalled();
      expect(turboVisit).not.toHaveBeenCalled();
      expect(enter.defaultPrevented).toBe(false);
      expect(space.defaultPrevented).toBe(false);
    });

    it('lets Enter on the title link through to the link', () => {
      const title = element.querySelector<HTMLAnchorElement>('.op-ian-item--middle-line a')!;

      expect(pressKey(title, 'Enter').defaultPrevented).toBe(false);
    });

    it('marks the notification as read', () => {
      element.querySelector<HTMLElement>('[data-test-selector="mark-as-read-button"]')!.click();

      expect(storeService.markAsRead).toHaveBeenCalledWith([17]);
    });
  });

  describe('for a work package notification', () => {
    beforeEach(() => render(workPackageNotification));

    it('requests the work package and shows the loading placeholder until it arrives', () => {
      expect(requestWorkPackage).toHaveBeenCalledWith('42');
      expect(element.querySelector('.op-ian-item--loading-indicator')).not.toBeNull();
      expect(element.querySelector('.op-ian-item--resource-label')).toBeNull();
    });

    it('renders an interactive row', () => {
      expect(row().getAttribute('role')).toEqual('button');
      expect(row().getAttribute('tabindex')).toEqual('0');
      expect(row().classList).not.toContain('op-ian-item--row_static');
    });

    it('opens the split screen on row click and Enter', () => {
      vi.useFakeTimers();

      row().click();
      vi.advanceTimersByTime(300);
      expect(storeService.openSplitScreen).toHaveBeenCalledWith('42', 'activity');

      const enter = pressKey(row(), 'Enter');
      vi.advanceTimersByTime(300);
      expect(enter.defaultPrevented).toBe(true);
      expect(storeService.openSplitScreen).toHaveBeenCalledTimes(2);
    });

    it('opens the full view on double click', () => {
      row().dispatchEvent(new MouseEvent('dblclick', { bubbles: true }));

      expect(turboVisit).toHaveBeenCalledWith(expect.stringMatching(/^\/work_packages\/42(\?|$)/), { action: 'advance' });
    });
  });
});
