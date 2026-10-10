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

import { Component, Injector, NO_ERRORS_SCHEMA, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, waitFor } from '@testing-library/dom';
import { config, of } from 'rxjs';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { shareModalUpdated } from 'core-app/features/work-packages/components/wp-share-modal/sharing.actions';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';
import { tableRefreshRequest } from 'core-app/features/work-packages/routing/wp-view-base/work-packages-view.actions';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { nextFrame, nextTask } from 'core-common/testing/timing';
import {
  buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices,
} from '../wp-fast-table/testing/table-harness';
import { buildWorkPackage, WorkPackageFixture } from '../wp-fast-table/testing/work-package-fixture';
import { WorkPackageTimelineTableController } from './timeline/container/wp-timeline-container.directive';
import { WorkPackagesTableComponent } from './wp-table.component';

/** Shows the table or the card view, as `wp-list-view` does when the viewport or query changes. */
@Component({
  template: '@if (showTable()) { <wp-table [configuration]="configuration" /> }',
  standalone: false,
})
class ListViewStandInComponent {
  showTable = signal(true);

  configuration = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    contextMenuEnabled: false,
    inlineCreateEnabled: false,
    dragAndDropEnabled: false,
  };
}

describe('WorkPackagesTableComponent lifecycle', () => {
  let fixture:ComponentFixture<ListViewStandInComponent>;
  let querySpace:IsolatedQuerySpace;
  let states:States;
  let timeline:WorkPackageViewTimelineService;
  let actions:ActionsService;
  let unhandled:unknown[];
  let previousHandler:typeof config.onUnhandledError;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [WorkPackagesTableComponent, ListViewStandInComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false, live$: () => of(null) } },
      ],
    }).compileComponents();

    const injector = TestBed.inject(Injector);
    injector.get(DisplayFieldService).addFieldType(TextDisplayField, 'text', ['String']);
    querySpace = TestBed.inject(IsolatedQuerySpace);
    states = TestBed.inject(States);
    timeline = TestBed.inject(WorkPackageViewTimelineService);
    actions = TestBed.inject(ActionsService);

    const query = buildQuery(['id', 'subject'], null, false, false);
    querySpace.query.putValue(query);
    querySpace.groups.putValue([]);
    initializeViewServices(injector, query);
    TestBed.inject(WorkPackageViewSumService).initialize(query);
    putResults([]);

    fixture = TestBed.createComponent(ListViewStandInComponent);
    document.body.appendChild(fixture.nativeElement as HTMLElement);
    fixture.detectChanges();

    unhandled = [];
    previousHandler = config.onUnhandledError;
    config.onUnhandledError = (error) => unhandled.push(error);
  });

  afterEach(() => {
    config.onUnhandledError = previousHandler;
    (fixture.nativeElement as HTMLElement).remove();
  });

  function putResults(fixtures:WorkPackageFixture[]) {
    const resources = fixtures.map(buildWorkPackage);
    resources.forEach((wp) => states.workPackages.get(wp.id!).putValue(wp));
    querySpace.results.putValue({ elements: resources, count: resources.length, total: resources.length } as unknown as WorkPackageCollectionResource);
  }

  /** Feeds a reloaded result set the way `WpStatesInitializationService.updateQuerySpace` does. */
  function reload(fixtures:WorkPackageFixture[]) {
    querySpace.tableRendered.clear();
    putResults(fixtures);
    querySpace.initialized.putValue(null);
  }

  function renderedIds():string[] {
    return (querySpace.tableRendered.value ?? [])
      .filter(({ workPackageId }) => workPackageId !== null)
      .map(({ workPackageId }) => workPackageId!);
  }

  // A table registered after `initialized` already has a value replays that
  // value and queues a stale render first, so wait for the requested one.
  async function render(fixtures:WorkPackageFixture[]) {
    reload(fixtures);
    await waitFor(() => expect(renderedIds()).toEqual(fixtures.map(({ id }) => id)));
  }

  /** Shows the table and registers the fast table as the timeline container directive would. */
  async function showTable(fixtures:WorkPackageFixture[]):Promise<HTMLElement> {
    fixture.componentInstance.showTable.set(true);
    fixture.detectChanges();
    const debug = fixture.debugElement.query(By.directive(WorkPackagesTableComponent));
    const element = debug.nativeElement as HTMLElement;
    const timelineBody = document.createElement('div');
    element.querySelector('.work-packages-tabletimeline--timeline-side')!.appendChild(timelineBody);
    (debug.componentInstance as WorkPackagesTableComponent)
      .registerTimeline({} as WorkPackageTimelineTableController, timelineBody);
    await render(fixtures);
    return element;
  }

  function showCards() {
    fixture.componentInstance.showTable.set(false);
    fixture.detectChanges();
  }

  /** The card view writes the rendered occurrences into the same query space state as the table. */
  function cardsRendered(ids:string[]) {
    querySpace.tableRendered.putValue(ids.map((id) => ({ classIdentifier: `wp-card-${id}`, workPackageId: id, hidden: false })));
  }

  function rowIds(element:HTMLElement):string[] {
    return Array.from(element.querySelectorAll<HTMLTableRowElement>('tr.wp-table--row[data-work-package-id]'))
      .map((row) => row.dataset.workPackageId!);
  }

  function countRefreshRequests():() => number {
    let count = 0;
    actions.ofType(tableRefreshRequest).subscribe(() => { count += 1; });
    return () => count;
  }

  async function settle() {
    await nextFrame();
    await nextTask();
  }

  it('stops reacting to the query space once the table is replaced by cards', async () => {
    const table = await showTable([{ id: '1' }, { id: '2' }]);
    showCards();

    timeline.setVisible(true);
    reload([{ id: '3' }]);
    await settle();

    expect(unhandled).toEqual([]);
    expect(querySpace.tableRendered.hasValue()).toBe(false);
    expect(rowIds(table)).toEqual(['1', '2']);
  });

  it('keeps a table shown again after cards reacting to the timeline', async () => {
    await showTable([{ id: '1' }]);
    showCards();
    const table = await showTable([{ id: '3' }]);

    timeline.setVisible(true);
    await settle();

    expect(unhandled).toEqual([]);
    expect(rowIds(table)).toEqual(['3']);
    expect(table.querySelector('.work-packages-tabletimeline--table-side')).toHaveClass('-timeline-visible');
    expect(table.querySelector('.work-packages-tabletimeline--timeline-side')).toHaveClass('-timeline-visible');
  });

  it('stays clean across repeated table and card transitions', async () => {
    await showTable([{ id: '1' }]);
    showCards();
    await showTable([{ id: '2' }]);
    showCards();

    timeline.setVisible(true);
    reload([{ id: '4' }]);
    await settle();

    expect(unhandled).toEqual([]);
    expect(querySpace.tableRendered.hasValue()).toBe(false);
  });

  it('refreshes once per sharing update, only through the live table', async () => {
    const refreshes = countRefreshRequests();
    await showTable([{ id: '1' }]);
    showCards();
    cardsRendered(['1']);

    actions.dispatch(shareModalUpdated({ workPackageId: '1' }));
    expect(refreshes()).toBe(0);

    await showTable([{ id: '1' }]);
    actions.dispatch(shareModalUpdated({ workPackageId: '1' }));
    expect(refreshes()).toBe(1);
  });
  it('preserves card entries when the removed table has queued a render', async () => {
    await showTable([{ id: '1' }]);
    reload([{ id: '2' }]);
    showCards();
    cardsRendered(['2']);
    await settle();
    expect(unhandled).toEqual([]);
    expect(querySpace.tableRendered.value).toEqual([
      { classIdentifier: 'wp-card-2', workPackageId: '2', hidden: false },
    ]);
  });

  it('can be destroyed before timeline registration and ignores a late registration', () => {
    const component = fixture.debugElement.query(By.directive(WorkPackagesTableComponent))
      .componentInstance as WorkPackagesTableComponent;
    expect(() => fixture.destroy()).not.toThrow();
    const controller = {} as WorkPackageTimelineTableController;
    expect(() => component.registerTimeline(controller, document.createElement('div'))).not.toThrow();
    expect(component.workPackageTable).toBeUndefined();
    expect(controller.workPackageTable).toBeUndefined();
  });

  it('destroys the previous table before replacing its timeline registration', async () => {
    await showTable([{ id: '1' }]);
    const component = fixture.debugElement.query(By.directive(WorkPackagesTableComponent))
      .componentInstance as WorkPackagesTableComponent;
    const previous = component.workPackageTable;
    component.registerTimeline({} as WorkPackageTimelineTableController, document.createElement('div'));
    expect(previous.destroyed).toBe(true);
    expect(component.workPackageTable.destroyed).toBe(false);
    await settle();
  });

  it('enables, disables and re-enables scrolling through timeline visibility', async () => {
    const element = await showTable([{ id: '1' }]);
    const tableSide = element.querySelector<HTMLElement>('.work-packages-tabletimeline--table-side')!;
    const timelineSide = element.querySelector<HTMLElement>('.work-packages-tabletimeline--timeline-side')!;
    for (const side of [tableSide, timelineSide]) {
      side.style.cssText = 'display: block; height: 40px; overflow: auto';
      const filler = document.createElement('div');
      filler.style.height = '1000px';
      side.appendChild(filler);
    }
    timeline.setVisible(true);
    tableSide.scrollTop = 30;
    fireEvent.scroll(tableSide);
    // Firefox snaps scroll offsets to device pixels, so a requested offset can land a fraction short.
    expect(timelineSide.scrollTop).toBeCloseTo(30, 0);
    timeline.setVisible(false);
    timelineSide.scrollTop = 60;
    fireEvent.scroll(timelineSide);
    expect(tableSide.scrollTop).toBeCloseTo(30, 0);
    timeline.setVisible(true);
    timelineSide.scrollTop = 90;
    fireEvent.scroll(timelineSide);
    expect(tableSide.scrollTop).toBeCloseTo(90, 0);
  });

});
