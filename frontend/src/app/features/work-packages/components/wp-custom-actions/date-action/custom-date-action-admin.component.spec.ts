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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormsModule } from '@angular/forms';
import { By } from '@angular/platform-browser';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CustomDateActionAdminComponent } from './custom-date-action-admin.component';

describe('CustomDateActionAdminComponent', () => {
  let fixture:ComponentFixture<CustomDateActionAdminComponent>;
  let component:CustomDateActionAdminComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [CustomDateActionAdminComponent],
      imports: [FormsModule],
      providers: [
        {
          provide: I18nService,
          useValue: {
            t:(key:string) => {
              switch (key) {
                case 'js.custom_actions.date.specific':
                  return 'on';
                case 'js.custom_actions.date.current_date':
                  return 'Current date';
                default:
                  return key;
              }
            },
          },
        },
      ],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
    }).compileComponents();

    fixture = TestBed.createComponent(CustomDateActionAdminComponent);
    component = fixture.componentInstance;
    fixture.nativeElement.dataset.fieldName = 'custom_action[actions][date]';
  });

  it('stores the current date sentinel when the operator is changed to current date', () => {
    fixture.detectChanges();

    const select = fixture.debugElement.query(By.css('select')).nativeElement as HTMLSelectElement;
    const hiddenInput = fixture.debugElement.query(By.css('input[type="hidden"]')).nativeElement as HTMLInputElement;

    select.value = 'current';
    select.dispatchEvent(new Event('change'));

    expect(component.selectedOperatorKey).toBe('current');
    expect(hiddenInput.value).toBe('%CURRENT_DATE%');
  });
});
