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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { CommonModule } from '@angular/common';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { GridAreaService } from 'core-app/shared/components/grids/grid/area.service';
import { GridDragAndDropService } from 'core-app/shared/components/grids/grid/drag-and-drop.service';
import { WidgetHeaderComponent } from 'core-app/shared/components/grids/widgets/header/header.component';

describe('WidgetHeaderComponent', () => {
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

    expect(heading.id).toEqual('widget-heading-1');
  });
});
