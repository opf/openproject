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
import { Component, Injector, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { screen } from '@testing-library/dom';
import { of } from 'rxjs';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackagesTableComponent } from 'core-app/features/work-packages/components/wp-table/wp-table.component';
import { WorkPackageViewBaselineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-baseline.service';
import { WorkPackageViewSumService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-sum.service';
import {
  buildQuery, FakeDragAndDropService, harnessProviders, initializeViewServices,
} from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { EditableToolbarTitleComponent } from 'core-app/shared/components/editable-toolbar-title/editable-toolbar-title.component';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { WidgetHeaderComponent } from './header.component';

@Component({ template: '', standalone: false })
class WidgetStandInComponent {}

describe('WidgetHeaderComponent', () => {
  let fixture:ComponentFixture<WidgetStandInComponent>;

  async function mount(isEditable:boolean) {
    TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule],
      declarations: [WidgetHeaderComponent, EditableToolbarTitleComponent, WorkPackagesTableComponent, WidgetStandInComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageViewSumService,
        { provide: WorkPackageViewBaselineService, useValue: { isActive: () => false, isChanged: () => false, live$: () => of(null) } },
        { provide: GridAreaService, useValue: { isEditable } },
        { provide: GridDragAndDropService, useValue: { isDraggable: false } },
      ],
    }).overrideTemplate(WidgetStandInComponent, `
    <widget-header name="Assigned to me" headingId="widget-heading">
    </widget-header>
    <wp-table [configuration]="{ keyboardNavigationEnabled: true, labelledBy: 'widget-heading' }" />
  `);

    const injector = TestBed.inject(Injector);
    const querySpace = TestBed.inject(IsolatedQuerySpace);
    const query = buildQuery(['id', 'subject'], null, false, false);
    querySpace.query.putValue(query);
    querySpace.groups.putValue([]);
    querySpace.results.putValue({ elements: [], count: 0, total: 0 } as unknown as WorkPackageCollectionResource);
    initializeViewServices(injector, query);
    TestBed.inject(WorkPackageViewSumService).initialize(query);

    fixture = TestBed.createComponent(WidgetStandInComponent);
    document.body.appendChild(fixture.nativeElement as HTMLElement);
    fixture.detectChanges();
    await fixture.whenStable();
  }

  afterEach(() => {
    (fixture.nativeElement as HTMLElement).remove();
  });

  it.each([true, false])('names the table exactly by the widget title when renameable is %s', async (renameable) => {
    await mount(renameable);

    expect(screen.getByRole('treegrid', { name: 'Assigned to me' })).toBeInTheDocument();
  });

  it('puts the heading id on the h3 around the title', async () => {
    await mount(false);

    expect(screen.getByRole('heading', { level: 3 })).toHaveAttribute('id', 'widget-heading');
  });
});

describe('WidgetHeaderComponent heading input', () => {
  let fixture:ComponentFixture<WidgetHeaderComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [WidgetHeaderComponent],
      imports: [CommonModule],
      providers: [
        { provide: GridAreaService, useValue: { isEditable: false } },
        { provide: GridDragAndDropService, useValue: { isDraggable: false } },
      ],
      schemas: [NO_ERRORS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(WidgetHeaderComponent);
  });

  it('applies the provided ID to the visible heading', () => {
    fixture.componentRef.setInput('headingId', 'widget-heading-1');
    fixture.componentRef.setInput('name', 'Widget title');
    fixture.detectChanges();

    const heading = fixture.nativeElement.querySelector('h3') as HTMLHeadingElement;

    expect(heading).toHaveAttribute('id', 'widget-heading-1');
  });
});
