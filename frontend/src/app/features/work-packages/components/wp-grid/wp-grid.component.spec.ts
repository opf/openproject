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
import { of, Subject } from 'rxjs';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import { WorkPackagesListService } from 'core-app/features/work-packages/components/wp-list/wp-list.service';
import { HighlightingMode } from '../wp-fast-table/builders/highlighting/highlighting-mode.const';
import { buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices } from '../wp-fast-table/testing/table-harness';
import { WorkPackagesTableComponent } from '../wp-table/wp-table.component';
import { WorkPackageTableConfiguration } from '../wp-table/wp-table-configuration';
import { WorkPackageTimelineTableController } from '../wp-table/timeline/container/wp-timeline-container.directive';
import { WorkPackagesGridComponent } from './wp-grid.component';

@Component({
  template: `@if (showGrid()) { <wp-grid [configuration]="configuration" /> }
    @if (showTable()) { <wp-table [configuration]="tableConfiguration" /> }`,
  standalone: false,
})
class GridHostComponent {
  showGrid = signal(true);

  showTable = signal(false);

  tableConfiguration = {
    actionsColumnEnabled: false, columnMenuEnabled: false, contextMenuEnabled: false,
    inlineCreateEnabled: false, dragAndDropEnabled: false,
  };

  configuration = new WorkPackageTableConfiguration(this.tableConfiguration);
}

describe('WorkPackagesGridComponent lifetime', () => {
  let fixture:ComponentFixture<GridHostComponent>;
  let updates:Subject<number>;
  let updateCount:number;
  let resolveReady:() => void;
  let current:{ mode:HighlightingMode };
  let component:WorkPackagesGridComponent;

  beforeEach(async () => {
    updates = new Subject<number>();
    updateCount = 0;
    const ready = new Promise<void>((resolve) => { resolveReady = resolve; });
    current = { mode: 'none' };
    TestBed.overrideComponent(WorkPackagesGridComponent, {
      add: { providers: [{
        provide: WorkPackageViewHighlightingService,
        useValue: { current, updates$: () => updates, onReady: () => ready },
      }] },
    });
    await TestBed.configureTestingModule({
      declarations: [WorkPackagesGridComponent, WorkPackagesTableComponent, GridHostComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false, live$: () => of(null) } },
        { provide: WorkPackagesListService, useValue: {} },
      ],
    }).compileComponents();
    const injector = TestBed.inject(Injector);
    const space = injector.get(IsolatedQuerySpace);
    const query = buildQuery(['id'], null, false, false);
    space.query.putValue(query);
    space.groups.putValue([]);
    initializeViewServices(injector, query);
    injector.get(WorkPackageViewSumService).initialize(query);
    space.results.putValue({ elements: [], count: 0, total: 0 } as unknown as WorkPackageCollectionResource);
    fixture = TestBed.createComponent(GridHostComponent);
    fixture.detectChanges();
    component = fixture.debugElement.query(By.directive(WorkPackagesGridComponent)).componentInstance as WorkPackagesGridComponent;
  });

  function changeMode(mode:HighlightingMode) {
    current.mode = mode;
    updateCount += 1;
    updates.next(updateCount);
  }

  function visibleMode():unknown {
    return fixture.debugElement.query(By.css('wp-card-view')).properties.highlightingMode;
  }

  it('renders highlighting updates and readiness while alive', async () => {
    changeMode('inline');
    expect(visibleMode()).toBe('inline');
    current.mode = 'status';
    resolveReady();
    await Promise.resolve();
    expect(visibleMode()).toBe('status');
  });

  it('ignores updates after the grid is removed by its host', () => {
    changeMode('inline');
    fixture.componentInstance.showGrid.set(false);
    fixture.detectChanges();
    changeMode('status');
    expect(component.highlightingMode).toBe('inline');
  });

  it('ignores readiness after fixture destruction', async () => {
    fixture.destroy();
    current.mode = 'status';
    resolveReady();
    await Promise.resolve();
    expect(component.highlightingMode).toBe('none');
  });

  it('keeps highlighting live across a sibling table lifetime without broadcasts', () => {
    const stop = vi.fn();
    TestBed.inject(IsolatedQuerySpace).stopAllSubscriptions.subscribe(stop);
    fixture.componentInstance.showTable.set(true);
    fixture.detectChanges();
    const debug = fixture.debugElement.query(By.directive(WorkPackagesTableComponent));
    const table = debug.componentInstance as WorkPackagesTableComponent;
    const body = document.createElement('div');
    (debug.nativeElement as HTMLElement).querySelector('.work-packages-tabletimeline--timeline-side')!.appendChild(body);
    table.registerTimeline({} as WorkPackageTimelineTableController, body);
    fixture.componentInstance.showTable.set(false);
    fixture.detectChanges();
    changeMode('inline');
    expect(visibleMode()).toBe('inline');
    expect(stop).not.toHaveBeenCalled();
    expect(table.workPackageTable.destroyed).toBe(true);
  });
});
