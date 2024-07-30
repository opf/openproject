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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { Injector } from '@angular/core';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { WorkPackageFilterValues } from 'core-app/features/work-packages/components/wp-edit-form/work-package-filter-values';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { WorkPackagesActivityService } from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import { WorkPackageCreateService } from 'core-app/features/work-packages/components/wp-new/wp-create.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { TypeResource } from 'core-app/features/hal/resources/type-resource';
import { HttpClientModule } from '@angular/common/http';
import { States } from 'core-app/core/states/states.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UIRouterModule } from '@uirouter/angular';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { HookService } from 'core-app/features/plugins/hook-service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { of } from 'rxjs';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';

describe('WorkPackageFilterValues', () => {
  let resource:WorkPackageResource;
  let injector:Injector;
  let halResourceService:HalResourceService;

  let changeset:WorkPackageChangeset;
  let subject:WorkPackageFilterValues;
  let filters:any[];
  let source:any;

  const WeekdayServiceStub = {
    loadWeekdays: () => of(true),
  };

  function setupTestBed() {
    // noinspection JSIgnoredPromiseFromCall
    void TestBed.configureTestingModule({
      imports: [
        UIRouterModule.forRoot({}),
        HttpClientModule,
      ],
      providers: [
        I18nService,
        { provide: WeekdayService, useValue: WeekdayServiceStub },
        States,
        IsolatedQuerySpace,
        HalEventsService,
        TimezoneService,
        PathHelperService,
        ConfigurationService,
        CurrentUserService,
        HookService,
        LoadingIndicatorService,
        HalResourceService,
        ToastService,
        HalResourceNotificationService,
        SchemaCacheService,
        WorkPackageNotificationService,
        WorkPackageCreateService,
        HalResourceEditingService,
        WorkPackagesActivityService,
      ],
    }).compileComponents();

    injector = TestBed.inject(Injector);
    halResourceService = injector.get(HalResourceService);

    resource = halResourceService.createHalResourceOfClass(WorkPackageResource, source, true);
    changeset = new WorkPackageChangeset(resource);

    const type1 = halResourceService.createHalResourceOfClass(
      TypeResource,
      { _type: 'Type', id: '1', _links: { self: { href: '/api/v3/types/1', name: 'Task' } } },
    );
    const type2 = halResourceService.createHalResourceOfClass(
      TypeResource,
      { _type: 'Type', id: '2', _links: { self: { href: '/api/v3/types/2', name: 'Bug' } } },
    );

    filters = [
      {
        id: 'type',
        operator: { id: '=' },
        values: [type1, type2],
      },
    ];

    subject = new WorkPackageFilterValues(injector, filters);
  }

  describe('when a filter value already exists in values', () => {
    describe('with the first type applied', () => {
      beforeEach(() => {
        source = {
          _type: 'WorkPackage',
          id: '1234',
          _links: {
            type: {
              href: '/api/v3/types/1',
              name: 'Task',
            },
          },
        };

        setupTestBed();
      });

      it('it should not apply the first value (Regression #30817)', (() => {
        subject.applyDefaultsFromFilters(changeset);

        expect(changeset.changedAttributes.length).toEqual(0);
        expect(changeset.value<HalResource>('type').href).toEqual('/api/v3/types/1');
      }));
    });

    describe('with the second type applied', () => {
      beforeEach(() => {
        source = {
          id: '1234',
          _links: {
            type: {
              href: '/api/v3/types/2',
              name: 'Bug',
            },
          },
        };

        setupTestBed();
      });

      it('it should not keep the second value (Regression #30817)', (() => {
        subject.applyDefaultsFromFilters(changeset);

        expect(changeset.changedAttributes.length).toEqual(0);
        expect(changeset.value<HalResource>('type').href).toEqual('/api/v3/types/2');
      }));
    });
  });
});
