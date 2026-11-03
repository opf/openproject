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
import { of, Subject } from 'rxjs';
import { type MockInstance } from 'vitest';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { INotification } from 'core-app/core/state/in-app-notifications/in-app-notification.model';
import {
  InAppNotificationsResourceService,
} from 'core-app/core/state/in-app-notifications/in-app-notifications.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { IanCenterService } from './ian-center.service';

describe('IanCenterService', () => {
  let service:IanCenterService;
  let selectedWorkPackage$:Subject<string>;
  let openSplitScreen:MockInstance<IanCenterService['openSplitScreen']>;
  let closeSplitScreen:MockInstance<IanCenterService['closeSplitScreen']>;

  function notificationFor(id:number, resourceHref:string):INotification[] {
    return [{ id, _links: { resource: { href: resourceHref } } } as unknown as INotification];
  }

  const workPackage3 = notificationFor(1, '/api/v3/work_packages/3');
  const document5 = notificationFor(2, '/api/v3/documents/5');
  const workPackage5 = notificationFor(3, '/api/v3/work_packages/5');
  const document7 = notificationFor(4, '/api/v3/documents/7');

  beforeEach(() => {
    selectedWorkPackage$ = new Subject<string>();

    TestBed.configureTestingModule({
      providers: [
        IanCenterService,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: InAppNotificationsResourceService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: UrlParamsService, useValue: { pathMatching$: () => selectedWorkPackage$ } },
        { provide: DeviceService, useValue: { isMobile: false } },
        { provide: IanBellService, useValue: {} },
      ],
    });

    service = TestBed.inject(IanCenterService);
    openSplitScreen = vi.spyOn(service, 'openSplitScreen').mockImplementation(() => undefined);
    closeSplitScreen = vi.spyOn(service, 'closeSplitScreen').mockImplementation(() => undefined);
  });

  describe('showNextNotification', () => {
    it('skips documents and opens the next work package', () => {
      service.notifications$ = of([document5, document7, workPackage5]);
      service.selectedNotificationIndex = 0;

      service.showNextNotification();

      expect(openSplitScreen).toHaveBeenCalledWith('5');
      expect(closeSplitScreen).not.toHaveBeenCalled();
    });

    it('falls back to a preceding work package when only documents follow', () => {
      service.notifications$ = of([workPackage3, document5, document7]);
      service.selectedNotificationIndex = 1;

      service.showNextNotification();

      expect(openSplitScreen).toHaveBeenCalledWith('3');
    });

    it('closes the split screen when only documents are left', () => {
      service.notifications$ = of([document5, document7]);
      service.selectedNotificationIndex = 0;

      service.showNextNotification();

      expect(openSplitScreen).not.toHaveBeenCalled();
      expect(closeSplitScreen).toHaveBeenCalledOnce();
    });

    it('closes the split screen when no notification is left', () => {
      service.notifications$ = of([]);
      service.selectedNotificationIndex = 0;

      service.showNextNotification();

      expect(openSplitScreen).not.toHaveBeenCalled();
      expect(closeSplitScreen).toHaveBeenCalledOnce();
    });
  });

  describe('selecting the notification of the opened work package', () => {
    it('ignores a document with the same id as the selected work package', () => {
      service.notifications$ = of([workPackage3, document5, workPackage5]);

      selectedWorkPackage$.next('5');

      expect(service.selectedNotificationIndex).toEqual(2);
      expect(service.selectedNotification).toBe(workPackage5[0]);
    });
  });
});
