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

import { HttpClientModule } from '@angular/common/http';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { inject, TestBed, waitForAsync } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageViewPaginationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-pagination.service';
import { WorkPackageTablePaginationComponent } from 'core-app/features/work-packages/components/wp-table/table-pagination/wp-table-pagination.component';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { IPaginationOptions, PaginationService } from 'core-app/shared/components/table-pagination/pagination-service';
import { PaginationInstance } from 'core-app/shared/components/table-pagination/pagination-instance';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { of } from 'rxjs';
import { WeekdayService } from 'core-app/core/days/weekday.service';

function setupMocks(paginationService:PaginationService) {
  const options:IPaginationOptions = {
    perPage: 0,
    perPageOptions: [10, 50],
    maxVisiblePageOptions: 1,
    optionsTruncationSize: 6,
  };

  // eslint-disable-next-line jasmine/no-unsafe-spy
  spyOn(paginationService, 'getMaxVisiblePageOptions').and.callFake(() => options.maxVisiblePageOptions);

  // eslint-disable-next-line jasmine/no-unsafe-spy
  spyOn(paginationService, 'getOptionsTruncationSize').and.callFake(() => options.optionsTruncationSize);

  // eslint-disable-next-line jasmine/no-unsafe-spy
  spyOn(paginationService, 'getPaginationOptions').and.callFake(() => options);
}

function pageString(element:JQuery) {
  return element.find('.op-pagination--range').text().trim();
}

describe('wpTablePagination Directive', () => {
  beforeEach(waitForAsync(() => {
    window.OpenProject = new OpenProject();

    const WeekdayServiceStub = {
      loadWeekdays: () => of(true),
    };

    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      imports: [
        HttpClientModule,
      ],
      declarations: [
        WorkPackageTablePaginationComponent,
        OpIconComponent,
      ],
      providers: [
        States,
        PaginationService,
        WorkPackageViewSortByService,
        PathHelperService,
        WorkPackageViewPaginationService,
        HalResourceService,
        { provide: WeekdayService, useValue: WeekdayServiceStub },
        ConfigurationService,
        IsolatedQuerySpace,
        I18nService,
      ],
    }).compileComponents();
  }));

  describe('page ranges and links', () => {
    it('should display the correct page range',
      inject([PaginationService], (paginationService:PaginationService) => {
        setupMocks(paginationService);
        const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
        const app:WorkPackageTablePaginationComponent = fixture.debugElement.componentInstance;
        const element = jQuery(fixture.elementRef.nativeElement);

        app.pagination = new PaginationInstance(1, 0, 10);
        app.update();
        fixture.detectChanges();
        expect(pageString(element)).toEqual('');

        app.pagination = new PaginationInstance(1, 11, 10);
        app.update();
        fixture.detectChanges();
        expect(pageString(element)).toEqual('(1 - 10/11)');
      }));

    describe('"next" link', () => {
      it('hidden on the last page',
        inject([PaginationService], (paginationService:PaginationService) => {
          setupMocks(paginationService);
          const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
          const app:WorkPackageTablePaginationComponent = fixture.debugElement.componentInstance;
          const element = jQuery(fixture.elementRef.nativeElement);

          app.pagination = new PaginationInstance(2, 11, 10);
          app.update();
          fixture.detectChanges();

          const liWithNextLink = element.find('.op-pagination--item-link_next').parent('li');
          const attrHidden = liWithNextLink.attr('hidden');
          expect(attrHidden).toBeDefined();
        }));
    });

    it('should display correct number of page number links',
      inject([PaginationService], (paginationService:PaginationService) => {
        setupMocks(paginationService);
        const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
        const app:WorkPackageTablePaginationComponent = fixture.debugElement.componentInstance;
        const element = jQuery(fixture.elementRef.nativeElement);

        function numberOfPageNumberLinks() {
          return element.find('button[rel="next"]').length;
        }

        app.pagination = new PaginationInstance(1, 1, 10);
        app.update();
        fixture.detectChanges();
        expect(numberOfPageNumberLinks()).toEqual(1);

        app.pagination = new PaginationInstance(1, 11, 10);
        app.update();
        fixture.detectChanges();
        expect(numberOfPageNumberLinks()).toEqual(2);

        app.pagination = new PaginationInstance(1, 59, 10);
        app.update();
        fixture.detectChanges();
        expect(numberOfPageNumberLinks()).toEqual(6);
      }));
  });
});
