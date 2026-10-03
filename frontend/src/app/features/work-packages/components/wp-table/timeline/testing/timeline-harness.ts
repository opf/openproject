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

import { HttpClient } from '@angular/common/http';
import { createComponent, EnvironmentInjector, Type } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { of, Subject } from 'rxjs';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { States } from 'core-app/core/states/states.service';
import { DayResourceService } from 'core-app/core/state/days/day.service';
import { WeekdayResourceService } from 'core-app/core/state/days/weekday.service';
import { WeekdayService } from 'core-app/core/days/weekday.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { WorkPackageRelationsService } from 'core-app/features/work-packages/components/wp-relations/wp-relations.service';
import { WorkPackageTable } from '../../../wp-fast-table/wp-fast-table';
import { WorkPackageTableConfiguration } from '../../wp-table-configuration';
import { WorkPackagesTableComponent } from '../../wp-table.component';
import { buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices } from '../../../wp-fast-table/testing/table-harness';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageTimelineTableController } from '../container/wp-timeline-container.directive';
import { WorkPackageTimelineHeaderController } from '../header/wp-timeline-header.directive';
import { WorkPackageTableTimelineGrid } from '../grid/wp-timeline-grid.directive';
import { WorkPackageTableTimelineRelations } from '../global-elements/wp-timeline-relations.directive';
import { WorkPackageTableTimelineStaticElements } from '../global-elements/wp-timeline-static-elements.directive';

export class TimelineTransport {
  days:Subject<ReturnType<typeof collection>>[] = [];
  dayRequests:string[] = [];
  relationRequests:string[][] = [];
  relations = new Subject<RelationResource[]>();
  errors:unknown[] = [];
}

function collection(elements:object[] = []) {
  return { _embedded: { elements }, _links: { self: { href: '/api/v3/days' } }, total: elements.length, count: elements.length };
}

export async function configureTimelineTesting() {
  await TestBed.configureTestingModule({
    declarations: [WorkPackageTimelineTableController, WorkPackageTimelineHeaderController,
      WorkPackageTableTimelineGrid, WorkPackageTableTimelineRelations, WorkPackageTableTimelineStaticElements],
  }).overrideComponent(WorkPackageTimelineTableController, {
    add: { providers: [
      ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
      { provide: TimelineTransport, useFactory: () => new TimelineTransport() },
      { provide: HalResourceEditingService, useValue: {
        typedState: () => ({ hasValue: () => false, value: undefined }),
        stopEditing: () => undefined,
        changeFor: (wp:WorkPackageResource) => new WorkPackageChangeset(wp),
      } },
      { provide: WorkPackageNotificationService, useFactory: (transport:TimelineTransport) => ({ handleRawError: (error:unknown) => transport.errors.push(error) }), deps: [TimelineTransport] },
      DayResourceService, WeekdayResourceService, WeekdayService, WorkPackageRelationsService,
      { provide: TurboRequestsService, useValue: {} },
      { provide: ToastService, useFactory: (transport:TimelineTransport) => ({ addError: (error:unknown) => transport.errors.push(error) }), deps: [TimelineTransport] },
      { provide: HttpClient, useFactory: (transport:TimelineTransport) => ({ get: (url:string) => {
        if (url === '/weekdays') return of(collection(Array.from({ length: 7 }, (_, index) => ({ day: index + 1, working: index < 5, _links: { self: { href: `/weekdays/${index + 1}` } } }))));
        transport.dayRequests.push(url);
        const response = new Subject<ReturnType<typeof collection>>();
        transport.days.push(response);
        return response;
      } }), deps: [TimelineTransport] },
      { provide: ApiV3Service, useFactory: (states:States, transport:TimelineTransport) => ({
        days: { week: { path: '/weekdays' }, nonWorkingDays: { path: '/days' } },
        relations: { loadInvolved: (ids:string[]) => { transport.relationRequests.push(ids); return transport.relations; } },
        work_packages: { cache: { current: (_id:string, fallback:unknown) => fallback },
          requireAll: (ids:string[]) => Promise.resolve(ids.map((id) => states.workPackages.get(id).value).filter(Boolean)),
          id: (id:string) => ({ requireAndStream: () => of(states.workPackages.get(id).value) }) },
        queries: { id: () => ({ order: { get: () => Promise.resolve({}) } }) },
      }), deps: [States, TimelineTransport] },
      { provide: WorkPackagesTableComponent, useValue: { registerTimeline: (controller:WorkPackageTimelineTableController, body:HTMLElement) => {
        controller.workPackageTable = makeTable(controller, body);
      } } },
    ] },
  }).compileComponents();
}

export function makeTable(controller:WorkPackageTimelineTableController, body = controller.timelineBody) {
  const root = controller.outerContainer.parentElement!;
  const tbody = document.createElement('tbody');
  return new WorkPackageTable(controller.injector, root, root.parentElement!, tbody, body, controller,
    new WorkPackageTableConfiguration({ actionsColumnEnabled: false, columnMenuEnabled: false, contextMenuEnabled: false, inlineCreateEnabled: false, dragAndDropEnabled: false }));
}

export function mountTimeline() {
  const fixture = TestBed.createComponent(WorkPackageTimelineTableController);
  const injector = fixture.debugElement.injector;
  const controller = fixture.componentInstance;
  const querySpace = injector.get(IsolatedQuerySpace);
  const query = buildQuery(['id', 'subject'], null, false, true);
  querySpace.query.putValue(query);
  querySpace.groups.putValue([]);
  querySpace.results.putValue({ elements: [] } as unknown as WorkPackageCollectionResource);
  querySpace.tableRendered.putValue([]);
  initializeViewServices(injector, query);
  const side = document.createElement('div');
  side.className = 'work-packages-tabletimeline--timeline-side';
  side.style.cssText = 'display: block; width: 300px; height: 200px; overflow: auto';
  side.appendChild(fixture.nativeElement as HTMLElement);
  const filler = document.createElement('div');
  filler.style.width = '10000px';
  side.appendChild(filler);
  document.body.appendChild(side);
  fixture.detectChanges();
  return { fixture, controller, injector, querySpace, side, transport: injector.get(TimelineTransport),
    child<T>(type:import('@angular/core').Type<T>):T { return fixture.debugElement.query(By.directive(type)).componentInstance as T; },
    finishDays(elements:object[] = [], request = 0) { this.transport.days[request].next(collection(elements)); this.transport.days[request].complete(); },
    destroy() { controller.workPackageTable.destroy(); fixture.destroy(); side.remove(); },
  };
}

export function mountTimelineChild<T>(type:Type<T>, mount:ReturnType<typeof mountTimeline>) {
  const ref = createComponent(type, { environmentInjector: TestBed.inject(EnvironmentInjector), elementInjector: mount.injector });
  mount.side.appendChild(ref.location.nativeElement as HTMLElement);
  ref.changeDetectorRef.detectChanges();
  return ref;
}
