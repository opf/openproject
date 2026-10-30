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
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { EditFieldControlsComponent } from './edit-field-controls.component';

describe('EditFieldControlsComponent', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [EditFieldControlsComponent, OpIconComponent],
    }).compileComponents();
  });

  it('allows an optional relation description without an emptiness callback', () => {
    const fixture = TestBed.createComponent(EditFieldControlsComponent);
    fixture.componentRef.setInput('fieldController', { required: false });
    fixture.componentRef.setInput('saveTitle', 'Save');
    fixture.componentRef.setInput('cancelTitle', 'Cancel');
    fixture.detectChanges();
    const save = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('button')!;
    const emit = vi.spyOn(fixture.componentInstance.onSave, 'emit');

    expect(save.disabled).toBe(false);
    save.click();
    expect(emit).toHaveBeenCalledOnce();
  });

  it.each([true, false])('disables a required field only when empty (%s)', (empty) => {
    const fixture = TestBed.createComponent(EditFieldControlsComponent);
    const isEmpty = vi.fn(() => empty);
    fixture.componentRef.setInput('fieldController', { required: true, isEmpty });
    fixture.detectChanges();

    expect((fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>('button')!.disabled).toBe(empty);
    expect(isEmpty).toHaveBeenCalled();
  });
});
