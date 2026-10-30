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
import { TestBed } from '@angular/core/testing';
import { BehaviorSubject, firstValueFrom, of } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { WorkPackageViewFiltersService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-filters.service';
import { TeamPlannerComponent } from './team-planner.component';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { OpCalendarService } from 'core-app/features/calendar/op-calendar.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CalendarDragDropService } from 'core-app/features/team-planner/team-planner/calendar-drag-drop.service';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { OpWorkPackagesCalendarService } from 'core-app/features/calendar/op-work-packages-calendar.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { DeviceService } from 'core-app/core/browser/device.service';

import { OpenprojectHalModule } from 'core-app/features/hal/openproject-hal.module';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

describe('TeamPlannerComponent resource and event contracts', () => {
  const filters = new BehaviorSubject<QueryFilterInstanceResource[]>([]);
  const lookupMany = vi.fn(() => of([]));
  const modify = vi.fn((_name:string, callback:(filter:QueryFilterInstanceResource) => void) => callback(filters.value[0]));
  const remove = vi.fn();
  const onCardClicked = vi.fn();

  afterEach(() => vi.restoreAllMocks());

  beforeEach(() => {
    vi.spyOn(TeamPlannerComponent.prototype, 'ngOnInit').mockImplementation(() => {});
    lookupMany.mockClear();
    modify.mockClear();
    remove.mockClear();
    onCardClicked.mockClear();
    filters.next([]);
    TestBed.configureTestingModule({
      imports: [CommonModule, OpenprojectHalModule],
      declarations: [TeamPlannerComponent],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: WorkPackageViewFiltersService, useValue: { live$: () => filters, find: () => filters.value[0], modify, remove } },
        { provide: PrincipalsResourceService, useValue: { lookupMany } },
        { provide: CalendarDragDropService, useValue: { isDragging$: new BehaviorSubject(undefined) } },
        { provide: OpWorkPackagesCalendarService, useValue: { onCardClicked } },
        { provide: LoadingIndicatorService, useValue: { table: { stop: () => {} } } },
        { provide: ConfigurationService, useValue: {} },
        { provide: CapabilitiesResourceService, useValue: {} },
        { provide: IsolatedQuerySpace, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: UrlParamsService, useValue: {} },
        { provide: OpCalendarService, useValue: { resizeObserver: () => {} } },
        { provide: HalResourceEditingService, useValue: {} },
        { provide: HalResourceNotificationService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
        { provide: ActionsService, useValue: {} },
        { provide: ToastService, useValue: {} },
        { provide: WeekdayService, useValue: {} },
        { provide: DeviceService, useValue: {} },
      ],
    });
    TestBed.overrideComponent(TeamPlannerComponent, { set: { template: '' } });
  });

  function assigneeFilter(ids:(string|null)[]):void {
    const filter = TestBed.inject(HalResourceService).createHalResource<QueryFilterInstanceResource>({ _type: 'QueryFilterInstance', _links: { self: { href: null }, filter: { href: '/api/v3/queries/filters/assignee' } } });
    filter.values = ids.map((id) => TestBed.inject(HalResourceService).createHalResource({ id, _links: { self: { href: id ? `/api/v3/users/${id}` : null } } }));
    filters.next([filter]);
  }

  function component():TeamPlannerComponent {
    return TestBed.runInInjectionContext(() => new TeamPlannerComponent());
  }

  it('looks up only persisted selected principals in their original order', async () => {
    assigneeFilter(['23', null, '7']);
    const planner = component();
    await firstValueFrom(planner.principals$);
    expect(lookupMany).toHaveBeenCalledWith(['23', '7']);
    expect(filters.value[0].values).toHaveLength(3);
    planner.ngOnDestroy();
  });

  it('looks up no principals when there is no selected assignee filter', async () => {
    const planner = component();
    await firstValueFrom(planner.principals$);
    expect(lookupMany).toHaveBeenCalledWith([]);
    planner.ngOnDestroy();
  });

  it('uses the actual assignee cardinality when removing one of several selections', () => {
    assigneeFilter(['23', '7']);
    const planner = component();
    planner.removeAssignee('/api/v3/users/23');
    expect(modify).toHaveBeenCalledWith('assignee', expect.any(Function));
    expect((filters.value[0].values as HalResource[]).map((principal) => principal.id)).toEqual(['7']);
    expect(remove).not.toHaveBeenCalled();
    planner.ngOnDestroy();
  });

  it('removes the assignee filter when the last real selection is removed', () => {
    assigneeFilter(['23']);
    const planner = component();
    planner.removeAssignee('/api/v3/users/23');
    expect(remove).toHaveBeenCalledWith('assignee');
    planner.ngOnDestroy();
  });

  it('preserves card click modifier events and persisted identities', () => {
    const planner = component();
    const event = new MouseEvent('click', { ctrlKey: true });
    planner.onCardClicked({ workPackageId: '23', event });
    expect(onCardClicked).toHaveBeenCalledWith({ workPackageId: '23', event });
    planner.ngOnDestroy();
  });

  it('accepts the Ruby integration custom detail without changing its wire format', () => {
    const fixture = TestBed.createComponent(TeamPlannerComponent);
    const open = vi.spyOn(fixture.componentInstance, 'openNewSplitCreate').mockImplementation(() => {});
    fixture.detectChanges();
    document.dispatchEvent(new CustomEvent('teamPlannerSelectDate', { detail: { start: '2026-10-26', end: '2026-10-28', assignee: '/api/v3/users/23' } }));
    expect(open).toHaveBeenCalledWith('2026-10-26', '2026-10-28', '/api/v3/users/23');
  });

  it('keeps each document listener scoped to the lifetime of its own planner', () => {
    const first = TestBed.createComponent(TeamPlannerComponent);
    const second = TestBed.createComponent(TeamPlannerComponent);
    const firstOpen = vi.spyOn(first.componentInstance, 'openNewSplitCreate').mockImplementation(() => {});
    const secondOpen = vi.spyOn(second.componentInstance, 'openNewSplitCreate').mockImplementation(() => {});
    first.detectChanges();
    second.detectChanges();
    const event = () => new CustomEvent('teamPlannerSelectDate', { detail: { start: '2026-10-26', end: '2026-10-28', assignee: '' } });
    document.dispatchEvent(event());
    expect(firstOpen).toHaveBeenCalledOnce();
    expect(secondOpen).toHaveBeenCalledOnce();
    first.destroy();
    document.dispatchEvent(event());
    expect(firstOpen).toHaveBeenCalledOnce();
    expect(secondOpen).toHaveBeenCalledTimes(2);
  });

  it('ignores an ordinary event and incomplete custom detail', () => {
    const planner = component();
    const open = vi.spyOn(planner, 'openNewSplitCreate').mockImplementation(() => {});
    planner.selectDateFromEvent(new Event('teamPlannerSelectDate'));
    planner.selectDateFromEvent(new CustomEvent('teamPlannerSelectDate'));
    planner.selectDateFromEvent(new CustomEvent('teamPlannerSelectDate', { detail: { start: '2026-10-26', end: '2026-10-28' } }));
    expect(open).not.toHaveBeenCalled();
    planner.ngOnDestroy();
  });

  it('ignores malformed custom detail instead of opening an invalid selection', () => {
    const fixture = TestBed.createComponent(TeamPlannerComponent);
    const open = vi.spyOn(fixture.componentInstance, 'openNewSplitCreate').mockImplementation(() => {});
    fixture.detectChanges();
    document.dispatchEvent(new CustomEvent('teamPlannerSelectDate', { detail: { start: 42, end: null, assignee: {} } }));
    expect(open).not.toHaveBeenCalled();
  });
});
