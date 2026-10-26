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

import { Component, Input, NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { EditableToolbarTitleComponent } from 'core-app/shared/components/editable-toolbar-title/editable-toolbar-title.component';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { WidgetHeaderComponent } from 'core-app/shared/components/grids/widgets/header/header.component';
import { WidgetWpTableComponent } from './wp-table.component';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: 'wp-embedded-table',
  template: '',
  standalone: false,
})
class EmbeddedTableStubComponent {
  @Input() configuration:Record<string, unknown>;
}

describe('WidgetWpTableComponent heading', () => {
  let fixture:ComponentFixture<WidgetWpTableComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule],
      declarations: [WidgetWpTableComponent, WidgetHeaderComponent, EditableToolbarTitleComponent, EmbeddedTableStubComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        { provide: GridAreaService, useValue: { isEditable: false } },
        { provide: GridDragAndDropService, useValue: { isDraggable: false } },
        { provide: ApiV3Service, useValue: {} },
        { provide: CurrentProjectService, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string, options?:{ defaultValue?:string }) => options?.defaultValue ?? key } },
      ],
    });

    fixture = TestBed.createComponent(WidgetWpTableComponent);
    fixture.componentInstance.resource = { identifier: 'work_packages_table', options: { queryId: '1', name: 'Assigned to me' } } as unknown as GridWidgetResource;
    fixture.detectChanges();
  });

  const headingId = () => (fixture.nativeElement as HTMLElement).querySelector('h3')!.id;
  const tableConfiguration = () => fixture.debugElement
    .query(By.directive(EmbeddedTableStubComponent))
    .componentInstance.configuration as Record<string, unknown>;

  it('labels the table by the id rendered on its own header', () => {
    expect(headingId()).toMatch(/^widget-heading-/);
    expect(tableConfiguration().labelledBy).toBe(headingId());
    expect(fixture.nativeElement).toHaveAttribute('aria-labelledby', headingId());
  });

  it('keeps the heading id after a rename', () => {
    const before = headingId();
    vi.spyOn(fixture.componentInstance as unknown as { setChangesetOptions:() => unknown }, 'setChangesetOptions').mockReturnValue({});

    fixture.componentInstance.resource.options.name = 'Renamed';
    fixture.componentInstance.renameWidget('Renamed');
    fixture.componentRef.changeDetectorRef.detectChanges();

    expect(headingId()).toBe(before);
    expect(tableConfiguration().labelledBy).toBe(before);
  });
});
