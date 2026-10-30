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

import { TestBed } from '@angular/core/testing';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { OpIconComponent } from '../icon/icon.component';
import { AutofocusDirective } from '../../directives/focus/autofocus.directive';
import { waitFor } from '@testing-library/dom';
import { SimpleChange } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { EditableToolbarTitleComponent } from './editable-toolbar-title.component';

describe('EditableToolbarTitleComponent loading title', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule],
      declarations: [EditableToolbarTitleComponent, OpIconComponent, AutofocusDirective],
      providers: [
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    }).compileComponents();
  });

  it('does not flag the title as empty while it is still loading', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('input')).not.toHaveClass('-error');
  });

  it('keeps the sizing shim hidden and mirrors the input title', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.detectChanges();
    const shim = fixture.nativeElement.querySelector('.editable-toolbar-title--input-shim') as HTMLElement;
    expect(shim).toHaveTextContent('Original');
    expect(getComputedStyle(shim).visibility).toBe('hidden');
  });

  it('disables in-flight input and renders a fixed small title when editing is unavailable', async () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.componentRef.setInput('inFlight', true);
    fixture.detectChanges();
    await fixture.whenStable();
    expect(fixture.nativeElement.querySelector('input')).toBeDisabled();
    fixture.componentRef.setInput('editable', false);
    fixture.componentRef.setInput('smallHeader', true);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('input')).toBeNull();
    expect(fixture.nativeElement.querySelector('.editable-toolbar-title--fixed')).toHaveTextContent('Original');
    expect(fixture.nativeElement.querySelector('.editable-toolbar-title--fixed')).toHaveClass('-small');
  });

  it('focuses and selects the title when initial focus is requested', async () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.componentRef.setInput('initialFocus', true);
    fixture.detectChanges();
    await fixture.whenStable();
    const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
    await waitFor(() => expect(input).toHaveFocus());
    expect(input.selectionStart).toBe(0);
    expect(input.selectionEnd).toBe('Original'.length);
  });

  it('resets on Escape and submits a changed title on Enter', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    fixture.componentRef.setInput('title', 'Original');
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
    const save = vi.spyOn(fixture.componentInstance.onSave, 'emit');
    fixture.componentInstance.selectedTitle = 'Draft';
    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    expect(fixture.componentInstance.selectedTitle).toBe('Original');
    expect(save).not.toHaveBeenCalled();
    fixture.componentInstance.selectedTitle = '  Changed  ';
    input.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
    expect(save).toHaveBeenCalledWith('Changed');
  });

  it('reports an empty submission when the title has not loaded', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    const component = fixture.componentInstance;
    component.ngOnChanges({ inputTitle: new SimpleChange(undefined, undefined, true) });
    const empty = vi.spyOn(component.onEmptySubmit, 'emit');
    const save = vi.spyOn(component.onSave, 'emit');

    component.save(new Event('submit', { cancelable: true }));

    expect(empty).toHaveBeenCalledOnce();
    expect(save).not.toHaveBeenCalled();
  });

  it('resets an unloaded title without emitting a save', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    const component = fixture.componentInstance;
    component.selectedTitle = 'Draft';
    const save = vi.spyOn(component.onSave, 'emit');
    const empty = vi.spyOn(component.onEmptySubmit, 'emit');

    component.reset();
    component.save(new Event('submit', { cancelable: true }));

    expect(component.inputTitle).toBeUndefined();
    expect(component.selectedTitle).toBe('');
    expect(save).not.toHaveBeenCalled();
    expect(empty).toHaveBeenCalledOnce();
  });

  it('keeps a loaded title editable and trims it on submission', () => {
    const fixture = TestBed.createComponent(EditableToolbarTitleComponent);
    const component = fixture.componentInstance;
    component.inputTitle = 'Original';
    component.ngOnChanges({ inputTitle: new SimpleChange(undefined, 'Original', true) });
    component.selectedTitle = '  Changed  ';
    const save = vi.spyOn(component.onSave, 'emit');

    component.save(new Event('submit', { cancelable: true }));

    expect(save).toHaveBeenCalledWith('Changed');
  });
});
