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

import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { StaticQueriesService } from 'core-app/shared/components/op-view-select/op-static-queries.service';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewPaginationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackagesListChecksumService } from 'core-app/features/work-packages/components/wp-list/wp-list-checksum.service';
import { WorkPackageStatesInitializationService } from 'core-app/features/work-packages/components/wp-list/wp-states-initialization.service';
import { WorkPackageViewDisplayRepresentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { WorkPackageViewIncludeSubprojectsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-include-subprojects.service';
import { HalEventsService } from 'core-app/features/hal/services/hal-events.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TestBed } from '@angular/core/testing';
import { throwError } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { WorkPackageEmbeddedTableComponent } from './embedded/wp-embedded-table.component';
import { WorkPackageTableConfiguration } from './wp-table-configuration';
import { WpTableConfigurationSortByTabComponent, SortModalObject } from './configuration-modal/tabs/sort-by-tab.component';
import { FakeDragAndDropService, harnessProviders } from '../wp-fast-table/testing/table-harness';

describe('table template boundaries', () => {
  beforeEach(async () => {
    vi.spyOn(OpenprojectWorkPackagesModule, 'bootstrapAttributeGroups').mockImplementation(() => undefined);
    TestBed.overrideModule(OpenprojectWorkPackagesModule, {
      set: {
        imports: [CommonModule, FormsModule],
        declarations: [WorkPackageEmbeddedTableComponent, WpTableConfigurationSortByTabComponent],
        exports: [WorkPackageEmbeddedTableComponent, WpTableConfigurationSortByTabComponent],
        providers: [], schemas: [],
      },
    });
    await TestBed.configureTestingModule({
      imports: [OpenprojectWorkPackagesModule],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        { provide: ApiV3Service, useValue: { queries: { find: () => throwError(() => new Error('Unavailable')) } } },
        { provide: I18nService, useValue: { t: (key:string, options?:{ message:string }) => options ? `${key}: ${options.message}` : key } },
        { provide: OpModalService, useValue: {} },
        { provide: PaginationService, useValue: { getPerPage: () => 20 } },
        { provide: AuthorisationService, useValue: {} },
        { provide: LoadingIndicatorService, useValue: {} },
        { provide: StaticQueriesService, useValue: {} },
        { provide: WorkPackageViewFiltersService, useValue: {} },
        { provide: WorkPackageViewSumService, useValue: {} },
        { provide: WorkPackageViewPaginationService, useValue: {} },
        { provide: WorkPackagesListChecksumService, useValue: {} },
        { provide: WorkPackageStatesInitializationService, useValue: {} },
        { provide: WorkPackageViewDisplayRepresentationService, useValue: {} },
        { provide: WorkPackageViewIncludeSubprojectsService, useValue: {} },
        { provide: HalEventsService, useValue: {} },
        { provide: DeviceService, useValue: {} },
      ],
    }).compileComponents();
  });

  afterEach(() => vi.restoreAllMocks());

  it('renders the formatted string after a failed query load', async () => {
    vi.spyOn(WorkPackageEmbeddedTableComponent.prototype, 'ngOnInit').mockImplementation(() => undefined);
    vi.spyOn(WorkPackageEmbeddedTableComponent.prototype, 'ngAfterViewInit').mockImplementation(() => undefined);
    const fixture = TestBed.createComponent(WorkPackageEmbeddedTableComponent);
    const component = fixture.componentInstance;
    component.configuration = new WorkPackageTableConfiguration({ projectContext: false });
    fixture.detectChanges();
    await component.loadQuery(false);
    fixture.detectChanges();
    const message = TestBed.inject(I18nService).t('js.error.embedded_table_loading', { message: 'Unavailable' });
    expect(component.error).toBe(message);
    expect((fixture.nativeElement as HTMLElement).querySelector('.op-toast.-error')?.textContent).toContain(message);
  });

  it('labels all three sorting criteria in order', () => {
    vi.spyOn(WpTableConfigurationSortByTabComponent.prototype, 'ngOnInit').mockImplementation(() => undefined);
    const fixture = TestBed.createComponent(WpTableConfigurationSortByTabComponent);
    const component = fixture.componentInstance;
    component.sortationObjects = [1, 2, 3].map(() => new SortModalObject(component.emptyColumn, 'asc'));
    fixture.detectChanges();
    const labels = Array.from((fixture.nativeElement as HTMLElement).querySelectorAll('label.form--label'));
    expect(labels.map((label) => label.textContent)).toEqual([
      component.text.sort_criteria_1, component.text.sort_criteria_2, component.text.sort_criteria_3,
    ]);
  });
});
