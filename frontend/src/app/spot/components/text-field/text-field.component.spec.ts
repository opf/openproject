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
  let input:HTMLInputElement;
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
    input = element.querySelector('input')!;
  });

  it('renders programmatic form values', async () => {
    expect(input.value).toBe('Initial');
    host.control.setValue('Replacement');
    await fixture.whenStable();
    expect(input.value).toBe('Replacement');
    host.control.reset();
    await fixture.whenStable();
    expect(input.value).toBe('Initial');
  });

  it('propagates user input and clear actions to the form', async () => {
    input.value = 'Typed';
    input.dispatchEvent(new Event('input', { bubbles: true }));
    await fixture.whenStable();
    expect(host.control.value).toBe('Typed');
    element.querySelector('button')!.click();
    await fixture.whenStable();
    expect(host.control.value).toBe('');
    expect(input.value).toBe('');
    expect(element.querySelector('button')).toBeNull();
  });

  it('reflects disabled and enabled form state', async () => {
    host.control.disable();
    await fixture.whenStable();
    expect(input.disabled).toBe(true);
    expect(element).toHaveClass('spot-text-field_disabled');
    expect(element.querySelector('button')).toBeNull();
    host.control.enable();
    await fixture.whenStable();
    expect(input.disabled).toBe(false);
    expect(element).not.toHaveClass('spot-text-field_disabled');
    expect(element.querySelector('button')).not.toBeNull();
  });

  it('reflects focus state and forwards focus events', async () => {
    const focus = new FocusEvent('focus');
    const blur = new FocusEvent('blur');
    input.dispatchEvent(focus);
    await fixture.whenStable();
    expect(element).toHaveClass('spot-text-field_focused');
    expect(host.focusEvents).toEqual([focus]);
    input.dispatchEvent(blur);
    await fixture.whenStable();
    expect(element).not.toHaveClass('spot-text-field_focused');
    expect(host.blurEvents).toEqual([blur]);
  });
});
