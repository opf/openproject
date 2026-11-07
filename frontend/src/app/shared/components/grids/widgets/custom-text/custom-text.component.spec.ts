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

import { CUSTOM_ELEMENTS_SCHEMA, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { EMPTY } from 'rxjs';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridAreaService } from '../../grid/area.service';
import { CustomTextEditFieldService } from './custom-text-edit-field.service';
import { WidgetCustomTextComponent } from './custom-text.component';

describe('WidgetCustomTextComponent', () => {
  it('renders formatted text and reacts to grid editability', async () => {
    const editable = signal(true);
    const handler = {
      htmlText: '<p>Hello grid</p>',
      active: false,
      valueChanged$: EMPTY,
      stateChanged$: EMPTY,
      initialize: vi.fn<CustomTextEditFieldService['initialize']>(),
      reinitialize: vi.fn<CustomTextEditFieldService['reinitialize']>(),
    };
    TestBed.configureTestingModule({
      declarations: [WidgetCustomTextComponent],
      imports: [CommonModule],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } satisfies Pick<I18nService, 't'> },
        { provide: GridAreaService, useValue: { isEditable: editable } satisfies Pick<GridAreaService, 'isEditable'> },
      ],
    }).overrideComponent(WidgetCustomTextComponent, {
      set: { providers: [{ provide: CustomTextEditFieldService, useValue: handler }] },
    });
    const fixture = TestBed.createComponent(WidgetCustomTextComponent);
    fixture.componentRef.setInput('resource', { options: { name: 'Notes', text: { raw: 'Hello grid' } } } satisfies Pick<GridWidgetResource, 'options'>);
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Hello grid');
    expect((fixture.nativeElement as HTMLElement).querySelector('button')).not.toBeNull();
    editable.set(false);
    await fixture.whenStable();
    expect(fixture.nativeElement as HTMLElement).toHaveTextContent('Hello grid');
    expect((fixture.nativeElement as HTMLElement).querySelector('button')).toBeNull();
  });
});
