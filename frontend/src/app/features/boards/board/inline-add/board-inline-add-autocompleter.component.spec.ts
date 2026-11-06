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

import { ChangeDetectorRef } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { WorkPackageCardDragAndDropService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-drag-and-drop.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import { BoardInlineAddAutocompleterComponent } from './board-inline-add-autocompleter.component';

describe('BoardInlineAddAutocompleterComponent', () => {
  it('excludes the rendered cards, not the stale query results', () => {
    const filtered = vi.fn((_filters:ApiV3FilterBuilder) => ({ get: () => of({ elements: [] }) }));
    const stubs = [
      { provide: IsolatedQuerySpace, useValue: { results: { value: { elements: [{ id: 'left-the-list' }] } }, query: { value: undefined } } },
      { provide: WorkPackageCardDragAndDropService, useValue: { currentOrder: ['dropped-here'] } },
      { provide: ApiV3Service, useValue: { withOptionalProject: () => ({ work_packages: { filtered } }) } },
      { provide: CurrentProjectService, useValue: { id: '1' } },
      { provide: I18nService, useValue: { t: (key:string) => key } },
      ...[
        PathHelperService,
        UrlParamsHelperService,
        WorkPackageNotificationService,
        HalResourceService,
        SchemaCacheService,
        ChangeDetectorRef,
      ].map((provide) => ({ provide, useValue: {} })),
    ];
    TestBed.configureTestingModule({ providers: stubs });
    const component = TestBed.runInInjectionContext(() => new BoardInlineAddAutocompleterComponent());

    component.getAutocompleterData('search').subscribe();

    const json = filtered.mock.calls[0][0].toJson();
    expect(json).toContain('dropped-here');
    expect(json).not.toContain('left-the-list');
  });
});
