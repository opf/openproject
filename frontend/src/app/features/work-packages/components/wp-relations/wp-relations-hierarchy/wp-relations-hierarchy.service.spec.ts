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
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { States } from 'core-app/core/states/states.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageRelationsHierarchyService } from './wp-relations-hierarchy.service';

describe('WorkPackageRelationsHierarchyService failure reporting', () => {
  const notification = { handleRawError: vi.fn(), showSave: vi.fn() };
  const events = { push: vi.fn() };
  const cache = { updateWorkPackage: vi.fn() };
  let service:WorkPackageRelationsHierarchyService;

  beforeEach(() => {
    vi.clearAllMocks();
    TestBed.configureTestingModule({ providers: [
      WorkPackageRelationsHierarchyService,
      States,
      { provide: PathHelperService, useValue: {} },
      { provide: HalEventsService, useValue: events },
      { provide: WorkPackageNotificationService, useValue: notification },
      { provide: ApiV3Service, useValue: { work_packages: { cache, id: (id:string) => ({ path: `/work_packages/${id}` }) } } },
    ] });
    service = TestBed.inject(WorkPackageRelationsHierarchyService);
  });

  it.each([true, false])('rethrows with resource-aware notification controlled by reportError=%s', async (reportError) => {
    const error = new Error('parent failed');
    const wp = { changeParent: () => Promise.reject(error) } as unknown as WorkPackageResource;
    const changing = reportError ? service.changeParent(wp, '2') : service.changeParent(wp, '2', { reportError: false });
    await expect(changing).rejects.toBe(error);
    expect(notification.handleRawError.mock.calls).toEqual(reportError ? [[error, wp]] : []);
  });

  it('retains successful cache, notification, and association events with drag-owned errors', async () => {
    const saved = {} as WorkPackageResource;
    const changeParent = vi.fn(() => Promise.resolve(saved));
    const wp = { lockVersion: 4, changeParent } as unknown as WorkPackageResource;
    expect(await service.changeParent(wp, '2', { reportError: false })).toBe(saved);
    expect(changeParent).toHaveBeenCalledWith({ lockVersion: 4, _links: { parent: { href: '/work_packages/2' } } });
    expect(cache.updateWorkPackage).toHaveBeenCalledExactlyOnceWith(saved);
    expect(notification.showSave).toHaveBeenCalledExactlyOnceWith(saved);
    expect(events.push).toHaveBeenCalledExactlyOnceWith(wp, { eventType: 'association', relatedWorkPackage: '2', relationType: 'parent' });
  });
});
