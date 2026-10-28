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
import { Injector } from '@angular/core';
import { of } from 'rxjs';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { SchemaProxy } from 'core-app/features/hal/schemas/schema-proxy';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';

describe('WorkPackageChangeset labels', () => {
  let halResourceService:HalResourceService;
  let changeset:WorkPackageChangeset;

  const buildPayload = () => (changeset as unknown as { buildPayloadFromChanges:() => { _links:Record<string, unknown> } })
    .buildPayloadFromChanges();

  beforeEach(() => {
    void TestBed.configureTestingModule({
      providers: [
        I18nService,
        States,
        TimezoneService,
        PathHelperService,
        ConfigurationService,
        HalResourceService,
        SchemaCacheService,
        WorkPackagesActivityService,
        { provide: WeekdayService, useValue: { loadWeekdays: () => of(true) } },
        { provide: HalResourceNotificationService, useValue: { handleRawError: () => false } },
        { provide: WorkPackageNotificationService, useValue: {} },
        { provide: WorkPackageCreateService, useValue: {} },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
      ],
    }).compileComponents();

    halResourceService = TestBed.inject(Injector).get(HalResourceService);

    const workPackage = halResourceService.createHalResourceOfClass(WorkPackageResource, {
      _type: 'WorkPackage',
      id: '1',
      lockVersion: 3,
      _links: {
        self: { href: '/api/v3/work_packages/1' },
        update: { href: '/api/v3/work_packages/1/form', method: 'post' },
        labels: [{ href: '/api/v3/labels/1', title: 'Bug' }],
      },
    }) as unknown as WorkPackageResource;

    const schema = halResourceService.createHalResourceOfClass(SchemaResource, {
      _type: 'Schema',
      labels: { name: 'Labels', type: '[]Label', writable: true },
    });

    vi.spyOn(SchemaCacheService.prototype, 'of').mockReturnValue(SchemaProxy.create(schema, workPackage));

    changeset = new WorkPackageChangeset(workPackage);
  });

  afterEach(() => vi.restoreAllMocks());

  const existing = () => halResourceService.createHalResourceOfType('Label', {
    _links: { self: { href: '/api/v3/labels/1', title: 'Bug' } },
  });

  it('sends new record labels as title-only links next to existing ones', () => {
    const newRecord = halResourceService.createHalResourceOfType('Label', { id: null, name: 'Needs triage', href: null });
    changeset.setValue('labels', [existing(), newRecord]);

    expect(buildPayload()._links.labels).toEqual([
      { href: '/api/v3/labels/1' },
      { href: null, title: 'Needs triage' },
    ]);
  });

  it('handles new record labels echoed back by the form', () => {
    const echoed = halResourceService.createHalResourceOfType('Label', {
      _links: { self: { href: null, title: 'Needs triage' } },
    });
    changeset.setValue('labels', [existing(), echoed]);

    expect(buildPayload()._links.labels).toEqual([
      { href: '/api/v3/labels/1' },
      { href: null, title: 'Needs triage' },
    ]);
  });

  it('leaves labels out of the payload when they were not changed', () => {
    expect(buildPayload()._links.labels).toBeUndefined();
  });

  it('keeps an emptied label list', () => {
    changeset.setValue('labels', []);

    expect(buildPayload()._links.labels).toEqual([]);
  });

  it('sends new record labels even when the reference resource has no labels link', () => {
    const bare = halResourceService.createHalResourceOfClass(WorkPackageResource, {
      _type: 'WorkPackage',
      id: '2',
      lockVersion: 1,
      _links: { self: { href: '/api/v3/work_packages/2' } },
    }) as unknown as WorkPackageResource;
    changeset = new WorkPackageChangeset(bare);

    const newRecord = halResourceService.createHalResourceOfType('Label', { id: null, name: 'Needs triage', href: null });
    changeset.setValue('labels', [newRecord]);

    const payload = buildPayload();

    expect(payload._links.labels).toEqual([{ href: null, title: 'Needs triage' }]);
    expect(payload).not.toHaveProperty('labels');
  });
});
