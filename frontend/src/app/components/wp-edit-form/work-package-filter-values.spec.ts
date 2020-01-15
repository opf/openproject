// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
// ++

import {TestBed} from "@angular/core/testing";
import {CurrentUserService} from "core-components/user/current-user.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {Injector} from "@angular/core";
import {WorkPackageCacheService} from "core-components/work-packages/work-package-cache.service";
import {SchemaCacheService} from "core-components/schemas/schema-cache.service";
import {WorkPackageFilterValues} from "core-components/wp-edit-form/work-package-filter-values";
import {HalResourceNotificationService} from "core-app/modules/hal/services/hal-resource-notification.service";
import {WorkPackagesActivityService} from "core-components/wp-single-view-tabs/activity-panel/wp-activity.service";
import {WorkPackageCreateService} from "core-components/wp-new/wp-create.service";

import {HalResourceEditingService} from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {TypeResource} from "core-app/modules/hal/resources/type-resource";
import {HttpClientModule} from "@angular/common/http";
import {States} from "core-components/states.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";
import {ConfigurationService} from "core-app/modules/common/config/configuration.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {UIRouterModule} from "@uirouter/angular";
import {WorkPackageDmService} from "core-app/modules/hal/dm-services/work-package-dm.service";
import {LoadingIndicatorService} from "core-app/modules/common/loading-indicator/loading-indicator.service";
import {OpenProjectFileUploadService} from "core-components/api/op-file-upload/op-file-upload.service";
import {HookService} from "core-app/modules/plugins/hook-service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {HalEventsService} from "core-app/modules/hal/services/hal-events.service";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {WorkPackageChangeset} from "core-components/wp-edit/work-package-changeset";
import {ConfigurationDmService} from "core-app/modules/hal/dm-services/configuration-dm.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";

describe('WorkPackageFilterValues', () => {
  let resource:WorkPackageResource;
  let injector:Injector;
  let halResourceService:HalResourceService;

  let changeset:WorkPackageChangeset;
  let subject:WorkPackageFilterValues;
  let filters:any[];
  let source:any;

  function setupTestBed() {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        UIRouterModule.forRoot({}),
        HttpClientModule
      ],
      providers: [
        I18nService,
        States,
        IsolatedQuerySpace,
        HalEventsService,
        TimezoneService,
        PathHelperService,
        ConfigurationService,
        ConfigurationDmService,
        CurrentUserService,
        HookService,
        OpenProjectFileUploadService,
        LoadingIndicatorService,
        WorkPackageDmService,
        HalResourceService,
        NotificationsService,
        HalResourceNotificationService,
        SchemaCacheService,
        WorkPackageNotificationService,
        WorkPackageCacheService,
        WorkPackageCreateService,
        HalResourceEditingService,
        WorkPackagesActivityService,
      ]
    }).compileComponents();

    injector = TestBed.get(Injector);
    halResourceService = injector.get(HalResourceService);

    resource = halResourceService.createHalResourceOfClass(WorkPackageResource, source, true);
    changeset = new WorkPackageChangeset(resource);

    let type1 = halResourceService.createHalResourceOfClass(
      TypeResource,
      { _type: 'Type', id: '1', _links: { self: { href: '/api/v3/types/1', name: 'Task' } } }
    );
    let type2 = halResourceService.createHalResourceOfClass(
      TypeResource,
      { _type: 'Type', id: '2', _links: { self: { href: '/api/v3/types/2', name: 'Bug' } } }
    );

    filters = [
      {
        id: 'type',
        operator: { id: '=' },
        values: [type1, type2]
      }
    ];

    subject = new WorkPackageFilterValues(injector, changeset, filters);
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
              name: 'Task'
            }
          }
        };

        setupTestBed();
      });

      it('it should not apply the first value (Regression #30817)', (() => {
        subject.applyDefaultsFromFilters();

        expect(changeset.changedAttributes.length).toEqual(0);
        expect(changeset.value('type').href).toEqual('/api/v3/types/1');
      }));
    });

    describe('with the second type applied', () => {
      beforeEach(() => {
        source = {
          id: '1234',
          _links: {
            type: {
              href: '/api/v3/types/2',
              name: 'Bug'
            }
          }
        };

        setupTestBed();
      });

      it('it should not apply the first value (Regression #30817)', (() => {
        subject.applyDefaultsFromFilters();

        expect(changeset.changedAttributes.length).toEqual(0);
        expect(changeset.value('type').href).toEqual('/api/v3/types/2');
      }));
    })

  });
});



