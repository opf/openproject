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
import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { fireEvent, screen, waitFor } from '@testing-library/dom';
import { OpIconComponent } from 'core-app/shared/components/icon/icon.component';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { EditFieldControlsComponent } from './edit-field-controls.component';

@Component({
  template: '',
  standalone: false,
})
class DescriptionEditorComponent {
  description = '';
  readonly fieldController = { required: true, isEmpty: () => this.description.trim() === '' };
  readonly save = vi.fn<() => void>();
  readonly cancel = vi.fn<() => void>();
}

describe('EditFieldControlsComponent', () => {
  let fixture:ComponentFixture<EditFieldControlsComponent>;

  async function render(field:EditFieldControlsComponent['field']) {
    await TestBed
      .configureTestingModule({
        imports: [CommonModule, OpTooltipDirective],
        declarations: [EditFieldControlsComponent, OpIconComponent],
      })
      .compileComponents();

    fixture = TestBed.createComponent(EditFieldControlsComponent);
    fixture.componentRef.setInput('saveTitle', 'Save');
    fixture.componentRef.setInput('cancelTitle', 'Cancel');
    fixture.componentRef.setInput('fieldController', field);
    await fixture.whenStable();
  }

  it('labels the icon-only save and cancel buttons with tooltips', async () => {
    await render({ required: false });

    expect(screen.getByRole('button', { name: 'Save' })).toBeEnabled();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeEnabled();
    expect(fixture.nativeElement.querySelectorAll('tool-tip')).toHaveLength(2);
  });

  it('keeps save disabled while a required field is empty', async () => {
    await render({ required: true, isEmpty: () => true });

    expect(screen.getByRole('button', { name: 'Save' })).toBeDisabled();
    expect(screen.getByRole('button', { name: 'Cancel' })).toBeEnabled();
  });

  it('rechecks the same controller when a description changes and emits both actions', async () => {
    TestBed.configureTestingModule({
      imports: [CommonModule, OpTooltipDirective],
      declarations: [DescriptionEditorComponent, EditFieldControlsComponent, OpIconComponent],
    }).overrideTemplate(DescriptionEditorComponent, `
      <input #input aria-label="Description" (input)="description = input.value">
      <edit-field-controls
        saveTitle="Save"
        cancelTitle="Cancel"
        [fieldController]="fieldController"
        (onSave)="save()"
        (onCancel)="cancel()"
      />
    `);
    const host = TestBed.createComponent(DescriptionEditorComponent);
    const input = await screen.findByRole('textbox', { name: 'Description' });
    const save = await screen.findByRole('button', { name: 'Save' });
    const cancel = await screen.findByRole('button', { name: 'Cancel' });
    expect(save).toBeDisabled();

    fireEvent.input(input, { target: { value: 'Description' } });
    await waitFor(() => expect(save).toBeEnabled());
    fireEvent.click(save);
    fireEvent.click(cancel);
    expect(host.componentInstance.save).toHaveBeenCalledOnce();
    expect(host.componentInstance.cancel).toHaveBeenCalledOnce();

    fireEvent.input(input, { target: { value: ' ' } });
    await waitFor(() => expect(save).toBeDisabled());
  });
});

describe('EditFieldControlsComponent input contracts', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CommonModule, OpTooltipDirective],
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
