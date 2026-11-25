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
import { FormControl, FormsModule, ReactiveFormsModule } from '@angular/forms';
import { createEvent, fireEvent, within } from '@testing-library/dom';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { SpotTextFieldComponent } from './text-field.component';

@Component({
  template: '',
  standalone: false,
})
class HostComponent {
  readonly control = new FormControl('Initial', { nonNullable: true });
  readonly focusEvents:FocusEvent[] = [];
  readonly blurEvents:FocusEvent[] = [];
}

describe('SpotTextFieldComponent', () => {
  let fixture:ComponentFixture<HostComponent>;
  let host:HostComponent;
  let input:HTMLElement;
  let element:HTMLElement;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      imports: [CommonModule, FormsModule, ReactiveFormsModule, IconModule],
      declarations: [HostComponent, SpotTextFieldComponent],
    });
    TestBed.overrideComponent(HostComponent, { set: {
      template: '<spot-text-field [formControl]="control" (inputFocus)="focusEvents.push($event)" (inputBlur)="blurEvents.push($event)" />',
    } });
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    await fixture.whenStable();
    element = (fixture.nativeElement as HTMLElement).querySelector('spot-text-field')!;
    input = within(element).getByRole('textbox');
  });

  it('renders programmatic form values', async () => {
    expect(input).toHaveValue('Initial');
    host.control.setValue('Replacement');
    await fixture.whenStable();
    expect(input).toHaveValue('Replacement');
    host.control.reset();
    await fixture.whenStable();
    expect(input).toHaveValue('Initial');
  });

  it('propagates user input and clear actions to the form', async () => {
    fireEvent.input(input, { target: { value: 'Typed' } });
    await fixture.whenStable();
    expect(host.control.value).toBe('Typed');
    fireEvent.click(within(element).getByRole('button'));
    await fixture.whenStable();
    expect(host.control.value).toBe('');
    expect(input).toHaveValue('');
    expect(within(element).queryByRole('button')).not.toBeInTheDocument();
  });

  it('reflects disabled and enabled form state', async () => {
    host.control.disable();
    await fixture.whenStable();
    expect(input).toBeDisabled();
    expect(element).toHaveClass('spot-text-field_disabled');
    expect(within(element).queryByRole('button')).not.toBeInTheDocument();
    host.control.enable();
    await fixture.whenStable();
    expect(input).toBeEnabled();
    expect(element).not.toHaveClass('spot-text-field_disabled');
    expect(within(element).getByRole('button')).toBeInTheDocument();
  });

  it('reflects focus state and forwards focus events', async () => {
    const focus = createEvent.focus(input);
    const blur = createEvent.blur(input);
    fireEvent(input, focus);
    await fixture.whenStable();
    expect(element).toHaveClass('spot-text-field_focused');
    expect(host.focusEvents).toEqual([focus]);
    fireEvent(input, blur);
    await fixture.whenStable();
    expect(element).not.toHaveClass('spot-text-field_focused');
    expect(host.blurEvents).toEqual([blur]);
  });
});
