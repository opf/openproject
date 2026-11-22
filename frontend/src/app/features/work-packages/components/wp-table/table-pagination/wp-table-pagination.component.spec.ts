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

import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { ComponentFixture, inject, TestBed } from '@angular/core/testing';
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
import { within } from '@testing-library/dom';
import { page as browserPage } from 'vitest/browser';
import { WeekdayService } from 'core-app/core/days/weekday.service';

function setupMocks(paginationService:PaginationService, overrides:Partial<IPaginationOptions> = {}) {
  const options:IPaginationOptions = {
    perPage: 0,
    perPageOptions: [10, 50],
    maxVisiblePageOptions: 1,
    optionsTruncationSize: 6,
    ...overrides,
  };

  vi.spyOn(paginationService, 'getMaxVisiblePageOptions').mockImplementation(() => options.maxVisiblePageOptions);

  vi.spyOn(paginationService, 'getOptionsTruncationSize').mockImplementation(() => options.optionsTruncationSize);

  vi.spyOn(paginationService, 'getPaginationOptions').mockImplementation(() => options);
}

function pageString(element:HTMLElement) {
  return element.querySelector('.op-pagination--range')?.textContent?.trim() ?? '';
}

describe('wpTablePagination Directive', () => {
  beforeEach(async () => {
    window.OpenProject = new OpenProject();

    const WeekdayServiceStub = {
      loadWeekdays: () => of(true),
    };

    await TestBed.configureTestingModule({
      declarations: [
        WorkPackageTablePaginationComponent,
        OpIconComponent,
      ],
      imports: [],
      providers: [
        States,
        PaginationService,
        WorkPackageViewSortByService,
        PathHelperService,
        WorkPackageViewPaginationService,
        HalResourceService,
        { provide: WeekdayService, useValue: WeekdayServiceStub },
        // PaginationService reads perPageOptions from ConfigurationService in its
        // constructor; in production the service is initialized before injection.
        { provide: ConfigurationService, useValue: { perPageOptions: [10, 50] } satisfies Pick<ConfigurationService, 'perPageOptions'> },
        IsolatedQuerySpace,
        I18nService,
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
      ]
    }).compileComponents();
  });

  describe('truncated page navigation', () => {
    let fixture:ComponentFixture<WorkPackageTablePaginationComponent>;
    let component:WorkPackageTablePaginationComponent;
    let element:HTMLElement;
    let viewport:{ width:number; height:number };

    beforeEach(async () => {
      viewport = { width: window.innerWidth, height: window.innerHeight };
      await browserPage.viewport(1280, 800);
      const paginationService = TestBed.inject(PaginationService);
      setupMocks(paginationService, { perPage: 10, maxVisiblePageOptions: 5, optionsTruncationSize: 1 });
      fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
      component = fixture.componentInstance;
      element = fixture.nativeElement;
    });

    afterEach(async () => {
      await browserPage.viewport(viewport.width, viewport.height);
    });

    async function renderPage(page:number, total:number):Promise<HTMLElement> {
      await fixture.whenStable();
      component.pagination = new PaginationInstance(page, total, 10);
      component.update();
      await fixture.whenStable();
      return within(element).getByRole('navigation', { name: component.text.page_navigation });
    }

    it('renders no ellipsis when all pages fit', async () => {
      const navigation = await renderPage(1, 30);

      expect(within(navigation).queryByText('…')).not.toBeInTheDocument();
      expect(within(navigation).getByText('3', { selector: 'button' })).toBeVisible();
    });

    it('renders an ellipsis before the final page links when pages are omitted', async () => {
      const navigation = await renderPage(1, 200);
      const ellipsis = within(navigation).getByText('…');
      const lastPage = within(navigation).getByText('20', { selector: 'button' });

      expect(ellipsis).toBeVisible();
      expect(lastPage).toBeVisible();
      expect(ellipsis.compareDocumentPosition(lastPage) & Node.DOCUMENT_POSITION_FOLLOWING).not.toBe(0);
    });

    it('renders only a leading ellipsis in the final-page window', async () => {
      const navigation = await renderPage(20, 200);
      const ellipsis = within(navigation).getByText('…');
      const firstWindowPage = within(navigation).getByText('16', { selector: 'button' });

      expect(ellipsis).toBeVisible();
      expect(ellipsis.compareDocumentPosition(firstWindowPage) & Node.DOCUMENT_POSITION_FOLLOWING).not.toBe(0);
      expect(within(navigation).getByText('20')).toHaveAttribute('aria-current', 'page');
      expect(within(navigation).queryByRole('button', { name: component.text.label_next })).not.toBeInTheDocument();
    });

    it('clears all numbered controls and ellipses when page selection is disabled', async () => {
      const navigation = await renderPage(10, 200);
      expect(component.prePageNumbers).not.toHaveLength(0);
      expect(within(navigation).getAllByText('…')).toHaveLength(2);

      component.showPageSelections = false;
      component.update();
      await fixture.whenStable();

      expect(component.prePageNumbers).toEqual([]);
      expect(component.pageNumbers).toEqual([]);
      expect(component.postPageNumbers).toEqual([]);
      expect(within(navigation).queryAllByRole('button')).toHaveLength(0);
      expect(within(navigation).queryByText('…')).not.toBeInTheDocument();
      expect(navigation.querySelector('[aria-current="page"]')).not.toBeInTheDocument();
      expect(within(navigation).getByText('(91 - 100/200)')).toBeVisible();
    });

    it('preserves navigation while numbered controls hide and return across the mobile breakpoint', async () => {
      const navigation = await renderPage(10, 200);
      const current = within(navigation).getByText('10');
      const first = within(navigation).getByText('1', { selector: 'button' });
      const last = within(navigation).getByText('20', { selector: 'button' });
      const ellipses = within(navigation).getAllByText('…');
      const previous = within(navigation).getByRole('button', { name: component.text.label_previous });
      const next = within(navigation).getByRole('button', { name: component.text.label_next });
      const updatePage = vi.spyOn(TestBed.inject(WorkPackageViewPaginationService), 'updateFromObject').mockImplementation(() => {});

      for (const width of [375, 543]) {
        await browserPage.viewport(width, 800);

        for (const control of [first, current, last, ...ellipses]) {
          expect(control).not.toBeVisible();
        }
        expect(previous).toBeVisible();
        expect(next).toBeVisible();
        expect(within(navigation).getByText('(91 - 100/200)')).toBeVisible();
      }

      previous.click();
      await fixture.whenStable();
      expect(updatePage).toHaveBeenLastCalledWith({ page: 9 });
      next.click();
      await fixture.whenStable();
      expect(updatePage).toHaveBeenLastCalledWith({ page: 11 });

      await browserPage.viewport(544, 800);

      for (const control of [first, current, last, ...ellipses]) {
        expect(control).toBeVisible();
      }
      expect(current).toHaveAttribute('aria-current', 'page');
      expect(previous).toBeVisible();
      expect(next).toBeVisible();
    });

    it('renders the current page between ellipses in a singleton window', async () => {
      vi.spyOn(TestBed.inject(PaginationService), 'getMaxVisiblePageOptions').mockReturnValue(1);
      const navigation = await renderPage(10, 200);
      const current = within(navigation).getByText('10');
      const ellipses = within(navigation).getAllByText('…');

      expect(current).toBeVisible();
      expect(current).toHaveAttribute('aria-current', 'page');
      expect(ellipses).toHaveLength(2);
      expect(ellipses[0].compareDocumentPosition(current) & Node.DOCUMENT_POSITION_FOLLOWING).not.toBe(0);
      expect(current.compareDocumentPosition(ellipses[1]) & Node.DOCUMENT_POSITION_FOLLOWING).not.toBe(0);
      expect(within(navigation).queryByText(component.text.no_other_page)).not.toBeInTheDocument();
    });

    it('suppresses numbered controls for genuinely single-page results', async () => {
      const navigation = await renderPage(1, 10);

      expect(navigation.querySelector('[aria-current="page"]')).not.toBeInTheDocument();
      expect(within(navigation).queryAllByRole('button')).toHaveLength(0);
      expect(within(navigation).queryByText('…')).not.toBeInTheDocument();
      expect(within(navigation).getByText(component.text.no_other_page)).toBeInTheDocument();
    });

    it('keeps Next usable when the current page ends the visible window', async () => {
      vi.spyOn(TestBed.inject(PaginationService), 'getMaxVisiblePageOptions').mockReturnValue(1);
      const navigation = await renderPage(10, 200);
      const updatePage = vi.spyOn(TestBed.inject(WorkPackageViewPaginationService), 'updateFromObject').mockImplementation(() => {});
      const next = within(navigation).getByRole('button', { name: component.text.label_next });

      expect(next).toBeVisible();
      next.click();
      await fixture.whenStable();

      expect(updatePage).toHaveBeenCalledWith({ page: 11 });
    });
  });

  describe('page ranges and links', () => {
    it('should display the correct page range', inject([PaginationService], (paginationService:PaginationService) => {
      setupMocks(paginationService);
      const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
      const app = fixture.componentInstance;
      const element:HTMLElement = fixture.nativeElement;

      app.pagination = new PaginationInstance(1, 0, 10);
      app.update();
      fixture.detectChanges();

      expect(pageString(element)).toEqual('');

      app.pagination = new PaginationInstance(1, 11, 10);
      app.update();
      fixture.detectChanges();

      expect(pageString(element)).toEqual('(1 - 10/11)');
    }));

    describe('"next" link', () => {
      it('hidden on the last page', inject([PaginationService], (paginationService:PaginationService) => {
        setupMocks(paginationService);
        const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
        const app = fixture.componentInstance;
        const element:HTMLElement = fixture.nativeElement;

        app.pagination = new PaginationInstance(2, 11, 10);
        app.update();
        fixture.detectChanges();

        const next = within(element).getByRole('button', { name: app.text.label_next, hidden: true });

        expect(next.parentElement).toHaveAttribute('hidden');
      }));
    });

    it('should display correct number of page number links', inject([PaginationService], (paginationService:PaginationService) => {
      setupMocks(paginationService);
      const fixture = TestBed.createComponent(WorkPackageTablePaginationComponent);
      const app = fixture.componentInstance;
      const element:HTMLElement = fixture.nativeElement;

      function numberOfPageNumberLinks() {
        return element.querySelectorAll('button[data-rel="next"]').length;
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
