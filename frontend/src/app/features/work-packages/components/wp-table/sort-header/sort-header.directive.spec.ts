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

import { CommonModule } from '@angular/common';
import { Injector, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { defer, finalize, Observable, of } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { WeekdayResourceService } from 'core-app/core/state/days/weekday.service';
import { QuerySortByResource, QUERY_SORT_BY_ASC, QUERY_SORT_BY_DESC } from 'core-app/features/hal/resources/query-sort-by-resource';
import { QueryColumn, queryColumnTypes } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageQueryStateService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-base.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewGroupByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-group-by.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageViewSortByService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sort-by.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { buildQuery, buildTable, FakeDragAndDropService, harnessProviders, initializeViewServices, TableHarness } from '../../wp-fast-table/testing/table-harness';
import { WorkPackageTable } from '../../wp-fast-table/wp-fast-table';
import { SortHeaderDirective } from './sort-header.directive';
import { primarySortDirection } from './primary-sort-direction';

describe('SortHeaderDirective', () => {
  let fixture:ComponentFixture<SortHeaderDirective>;
  let harness:TableHarness;
  const tables:TableHarness[] = [];
  const subject = { id: 'subject', name: 'Subject', href: '/api/v3/queries/columns/subject', _type: queryColumnTypes.PROPERTY } as QueryColumn;
  const status = { id: 'status', name: 'Status', href: '/api/v3/queries/columns/status', _type: queryColumnTypes.PROPERTY } as QueryColumn;
  const category = { id: 'category', name: 'Category', href: '/api/v3/queries/columns/category', _type: queryColumnTypes.PROPERTY } as QueryColumn;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [SortHeaderDirective],
      imports: [CommonModule],
      schemas: [NO_ERRORS_SCHEMA],
      providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
    }).overrideComponent(SortHeaderDirective, {
      add: {
        providers: [
          WorkPackageViewBaselineService, ConfigurationService, TimezoneService, WeekdayService,
          { provide: DayResourceService, useValue: { requireNonWorkingYears$: () => of([]) } },
          { provide: WeekdayResourceService, useValue: { requireCollection: () => of([]) } },
        ],
      },
    }).compileComponents();
    initializeViewServices(TestBed.inject(Injector), buildQuery(['id', 'subject'], null, false, false));
    TestBed.inject(IsolatedQuerySpace).available.sortBy.putValue([]);
    harness = buildTable({ workPackages: [], configuration: { hierarchyToggleEnabled: true } });
    tables.push(harness);
  });

  afterEach(async () => {
    fixture?.destroy();
    await Promise.all(tables.splice(0).map((table) => table.destroy()));
    vi.restoreAllMocks();
  });

  function mount(column:QueryColumn, table:WorkPackageTable|undefined = harness.table) {
    fixture = TestBed.createComponent(SortHeaderDirective);
    fixture.componentRef.setInput('headerColumn', column);
    fixture.componentRef.setInput('table', table);
    fixture.detectChanges();
    return fixture.nativeElement as HTMLElement;
  }

  function makeSortable(...columns:QueryColumn[]) {
    TestBed.inject(IsolatedQuerySpace).available.sortBy.putValue(
      columns.map((column) => ({ column, direction: { href: QUERY_SORT_BY_ASC } }) as QuerySortByResource),
    );
  }

  function sortBy(...criteria:[QueryColumn, string][]) {
    TestBed.inject(WorkPackageViewSortByService).update(
      criteria.map(([column, href]) => ({ column, direction: { href } }) as QuerySortByResource),
    );
  }

  const sortLink = (host:HTMLElement) => host.querySelector<HTMLAnchorElement>('a[href="#"]');
  const relationIcon = (host:HTMLElement) => host.querySelector('op-icon[icon-classes*="relations-header--icon"]');
  const hierarchyIconClasses = (host:HTMLElement) => (host.querySelector('.hierarchy-header--icon op-icon') as unknown as Record<string, string>|null)?.['icon-classes'];

  describe('presentation', () => {
    it.each([
      [queryColumnTypes.RELATION_TO_TYPE, { type: { name: 'Milestone', href: '/api/v3/types/2' } }, 'Milestone'],
      [queryColumnTypes.RELATION_OF_TYPE, { relationType: 'relates' }, 'js.relation_labels.relates'],
      [queryColumnTypes.RELATION_CHILD, {}, 'Children'],
    ])('names a %s relation header on first detection without a table', (type, attributes, label) => {
      const host = mount({ id: 'relations', name: 'Children', _type: type, ...attributes } as unknown as QueryColumn, undefined);

      expect(host).toHaveTextContent(label);
      expect(relationIcon(host)).not.toBeNull();
      expect(host.querySelector('a')).toHaveAttribute('title', 'Children');
    });

    it('renders the hierarchy toggle for the subject column on first detection', () => {
      const host = mount(subject);

      const toggle = host.querySelector('.hierarchy-header--icon');
      expect(toggle).toHaveAttribute('title', 'js.work_packages.hierarchy.show');
      expect(hierarchyIconClasses(host)).toBe('icon icon-no-hierarchy');
    });

    it('resets presentation when a relation input becomes an ordinary column', () => {
      const host = mount({ id: 'relations', name: 'Children', _type: queryColumnTypes.RELATION_CHILD } as QueryColumn);
      expect(relationIcon(host)).not.toBeNull();

      fixture.componentRef.setInput('headerColumn', status);
      fixture.detectChanges();

      expect(host).toHaveTextContent('Status');
      expect(host).not.toHaveTextContent('Children');
      expect(relationIcon(host)).toBeNull();
    });
  });

  describe('view state notifications', () => {
    it('follows hierarchy changes made elsewhere', async () => {
      const host = mount(subject);

      TestBed.inject(WorkPackageViewHierarchiesService).setEnabled(true);
      await fixture.whenStable();

      const toggle = host.querySelector('.hierarchy-header--icon');
      expect(toggle).toHaveAttribute('title', 'js.work_packages.hierarchy.hide');
      expect(hierarchyIconClasses(host)).toBe('icon icon-hierarchy');
    });

    it('turns grouping off when hierarchy is enabled from the header', () => {
      mount(subject);
      const hierarchies = TestBed.inject(WorkPackageViewHierarchiesService);
      const groupBy = TestBed.inject(WorkPackageViewGroupByService);
      groupBy.update({ id: 'status', href: '/api/v3/queries/group_bys/status' } as typeof groupBy.current);

      fixture.componentInstance.toggleHierarchy(new MouseEvent('click'));
      expect(hierarchies.isEnabled).toBe(true);
      expect(groupBy.isEnabled).toBe(false);

      fixture.componentInstance.toggleHierarchy(new MouseEvent('click'));
      expect(hierarchies.isEnabled).toBe(false);
    });

    it('repaints the baseline warning when baseline mode changes', async () => {
      const host = mount(category);
      const baseline = fixture.debugElement.injector.get(WorkPackageViewBaselineService);
      const warning = () => host.querySelector('.generic-table--sort-header--error-indicator');
      expect(warning()).toBeNull();

      baseline.update(['2026-10-01']);
      await fixture.whenStable();
      expect(warning()).not.toBeNull();

      baseline.disable();
      await fixture.whenStable();
      expect(warning()).toBeNull();
    });

    it('becomes sortable when sort criteria become available for an unchanged sort', async () => {
      const host = mount(status);
      expect(sortLink(host)).toBeNull();
      expect(host.querySelector('a')).toHaveTextContent('Status');

      makeSortable(status);
      await fixture.whenStable();

      expect(sortLink(host)).not.toBeNull();
    });

    it.each([
      [QUERY_SORT_BY_ASC, 'asc', 'desc'],
      [QUERY_SORT_BY_DESC, 'desc', 'asc'],
    ])('shows the primary %s direction', async (href, shown, hidden) => {
      makeSortable(status);
      const host = mount(status);

      sortBy([status, href]);
      await fixture.whenStable();

      expect(sortLink(host)).toHaveClass('sort', shown);
      expect(sortLink(host)).not.toHaveClass(hidden);
    });

    it('shows no direction as a secondary criterion or once sorting is cleared', async () => {
      makeSortable(status, subject);
      const host = mount(status);

      sortBy([subject, QUERY_SORT_BY_ASC], [status, QUERY_SORT_BY_DESC]);
      await fixture.whenStable();
      expect(sortLink(host)).not.toHaveClass('sort');

      sortBy([status, QUERY_SORT_BY_DESC]);
      await fixture.whenStable();
      expect(sortLink(host)).toHaveClass('sort', 'desc');

      sortBy();
      await fixture.whenStable();
      expect(sortLink(host)).not.toHaveClass('sort');
    });

    it('settles on the republished sort after a reload clears the view state', async () => {
      makeSortable(status);
      const host = mount(status);
      sortBy([status, QUERY_SORT_BY_ASC]);
      await fixture.whenStable();

      const service = TestBed.inject(WorkPackageViewSortByService);
      service.clear('reload');
      const query = buildQuery(['id', 'status'], null, false, false);
      query.sortBy = [{ column: status, direction: { href: QUERY_SORT_BY_DESC } } as QuerySortByResource];
      service.initialize(query, query.results);
      await fixture.whenStable();

      expect(sortLink(host)).toHaveClass('sort', 'desc');
      expect(sortLink(host)).not.toHaveClass('asc');
    });
  });

  describe('subscriptions', () => {
    function trackSubscriptions():string[] {
      const log:string[] = [];
      const track = <T>(name:string, source:() => Observable<T>) => defer(() => {
        log.push(`+${name}`);
        return source().pipe(finalize(() => log.push(`-${name}`)));
      });
      const bridgeName = (service:object) => {
        if (service instanceof WorkPackageViewSortByService) return 'sort';
        if (service instanceof WorkPackageViewHierarchiesService) return 'hierarchy';
        if (service instanceof WorkPackageViewBaselineService) return 'baseline';
        return 'other';
      };
      /* eslint-disable @typescript-eslint/unbound-method */
      const live = WorkPackageQueryStateService.prototype.live$;
      const ready = WorkPackageViewSortByService.prototype.onReadyWithAvailable;
      /* eslint-enable @typescript-eslint/unbound-method */
      vi.spyOn(WorkPackageQueryStateService.prototype, 'live$').mockImplementation(function trackedLive(this:WorkPackageQueryStateService<unknown>) {
        return track(bridgeName(this), () => live.call(this));
      });
      vi.spyOn(WorkPackageViewSortByService.prototype, 'onReadyWithAvailable').mockImplementation(function trackedReady(this:WorkPackageViewSortByService) {
        return track('ready', () => ready.call(this));
      });
      return log;
    }

    it('subscribes once per bridge, survives table replacement and unsubscribes on destroy', async () => {
      const replacement = buildTable({ workPackages: [] });
      tables.push(replacement);
      const log = trackSubscriptions();
      mount(subject);
      expect([...log].sort()).toEqual(['+baseline', '+hierarchy', '+ready', '+sort']);

      fixture.componentRef.setInput('table', replacement.table);
      fixture.detectChanges();
      harness.table.destroy();
      await fixture.whenStable();
      expect(log).toHaveLength(4);

      fixture.destroy();
      expect(log.slice(4).sort()).toEqual(['-baseline', '-hierarchy', '-ready', '-sort']);
    });
  });
});

describe('primarySortDirection', () => {
  const subject = { id: 'subject', href: '/api/v3/queries/columns/subject' } as QueryColumn;
  const status = { id: 'status', href: '/api/v3/queries/columns/status' } as QueryColumn;
  const criterion = (column:QueryColumn, href:string) => ({ column, direction: { href } }) as QuerySortByResource;

  it.each([
    [QUERY_SORT_BY_ASC, 'asc'],
    [QUERY_SORT_BY_DESC, 'desc'],
  ])('reads the primary criterion %s as %s', (href, expected) => {
    expect(primarySortDirection([criterion(subject, href), criterion(status, QUERY_SORT_BY_ASC)], subject)).toBe(expected);
  });

  it('ignores secondary criteria and unsorted columns', () => {
    const sortBy = [criterion(subject, QUERY_SORT_BY_ASC), criterion(status, QUERY_SORT_BY_DESC)];

    expect(primarySortDirection(sortBy, status)).toBeNull();
    expect(primarySortDirection([], subject)).toBeNull();
  });
});
