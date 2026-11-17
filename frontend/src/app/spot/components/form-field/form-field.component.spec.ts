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

/* eslint vitest/expect-expect: ["error", { "assertFunctionNames": ["expect", "expectError"] }] */

import { CommonModule } from '@angular/common';
import { Component, signal } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Subject } from 'rxjs';
import { fireEvent } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SpotFormFieldComponent } from './form-field.component';
import { SpotFormBindingDirective } from './form-binding.directive';
import { SpotSelectorFieldComponent } from '../selector-field/selector-field.component';

@Component({ template: '', standalone: false })
class HostComponent {
  readonly control = signal(new FormControl('', { nonNullable: true, validators: (control) => Validators.required(control) }));
  readonly form = new FormGroup({ name: this.control() });
  readonly alternate = signal(false);
  readonly showInput = signal(true);
  readonly secondControl = new FormControl('', { nonNullable: true, validators: (control) => Validators.required(control) });
  readonly mode = signal<'blur'|'change'|'submit'|'never'>('blur');
}

describe.each([
  { component: SpotFormFieldComponent, selector: 'spot-form-field' },
  { component: SpotSelectorFieldComponent, selector: 'spot-selector-field' },
])('$selector validation', ({ component, selector }) => {
  let fixture:ComponentFixture<HostComponent>;
  let host:HostComponent;
  let element:HTMLElement;

  async function render(options:{ projected?:boolean; binding?:boolean; parentForm?:boolean; named?:boolean; replaceable?:boolean } = {}) {
    const { projected = false, binding = false, parentForm = true, named = false, replaceable = false } = options;
    const input = replaceable ? `@if (showInput()) {
      @if (alternate()) { <span slot="input" [spotFormBinding]="secondControl"></span> }
      @else { <span slot="input" [spotFormBinding]="control()"></span> }
    }` : named ? '<input slot="input" formControlName="name">' : binding ? '<span slot="input" [spotFormBinding]="control()"></span>'
      : '<input slot="input" [formControl]="control()">';
    const field = `<${selector} label="Name" [showValidationErrorOn]="mode()" ${projected ? '' : '[control]="control()"'}>
      ${projected ? input : '<span slot="input">Input</span>'}
      <span slot="description">Description</span><span slot="errors">Required</span>
    </${selector}>`;
    TestBed.configureTestingModule({
      imports: [CommonModule, ReactiveFormsModule],
      declarations: [HostComponent, SpotFormFieldComponent, SpotSelectorFieldComponent, SpotFormBindingDirective],
      providers: [{ provide: I18nService, useValue: { t: (key:string) => key } }],
    });
    TestBed.overrideComponent(HostComponent, { set: { template: parentForm ? `<form [formGroup]="form">${field}</form>` : field } });
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    await fixture.whenStable();
    element = (fixture.nativeElement as HTMLElement).querySelector(selector)!;
  }

  function expectError(visible:boolean) {
    const errors = element.querySelector('.spot-form-field--errors');
    if (visible) {
      expect(element).toHaveClass('spot-form-field_invalid');
      expect(errors).toBeInTheDocument();
      expect(errors).toHaveTextContent('Required');
    } else {
      expect(element).not.toHaveClass('spot-form-field_invalid');
      expect(errors).not.toBeInTheDocument();
    }
    const description = element.querySelector('.spot-form-field--description')!;
    expect(element.querySelector('.spot-form-field--input'))
      .toHaveAttribute('aria-describedby', (errors ?? description).id);
  }

  it.each([false, true])('updates touched validation with a projected control: %s', async (projected) => {
    await render({ projected, parentForm: false });
    expect(element).toHaveTextContent('Name');
    expect(element).toHaveTextContent('Description');
    expectError(false);
    host.control().markAsTouched();
    await fixture.whenStable();
    expectError(true);
    host.control().markAsUntouched();
    await fixture.whenStable();
    expectError(false);
  });

  it('updates dirty validation and validity without replacing the control', async () => {
    await render();
    host.mode.set('change');
    await fixture.whenStable();
    host.control().markAsDirty();
    await fixture.whenStable();
    expectError(true);
    host.control().setValue('Valid');
    await fixture.whenStable();
    expectError(false);
    host.control().setValue('');
    await fixture.whenStable();
    expectError(true);
    host.control().markAsPristine();
    await fixture.whenStable();
    expectError(false);
  });

  it('renders async validation completion', async () => {
    await render();
    const result = new Subject<null|{ unavailable:true }>();
    host.control().setAsyncValidators(() => result);
    host.control().markAsTouched();
    host.control().setValue('Candidate');
    await fixture.whenStable();
    expectError(false);
    result.next({ unavailable: true });
    result.complete();
    await fixture.whenStable();
    expectError(true);
  });

  it('updates submit validation and clears it on form reset', async () => {
    await render({ projected: true });
    host.mode.set('submit');
    await fixture.whenStable();
    expectError(false);
    const form = (fixture.nativeElement as HTMLElement).querySelector('form')!;
    fireEvent.submit(form);
    await fixture.whenStable();
    expectError(true);
    fireEvent.reset(form);
    await fixture.whenStable();
    expectError(false);
  });

  it.each([false, true])('follows replacement controls with projection: %s', async (projected) => {
    await render({ projected, parentForm: false });
    const previous = host.control();
    const replacement = new FormControl('', { nonNullable: true, validators: (control) => Validators.required(control) });
    host.control.set(replacement);
    await fixture.whenStable();
    previous.markAsTouched();
    await fixture.whenStable();
    expectError(false);
    replacement.markAsTouched();
    await fixture.whenStable();
    expectError(true);
  });

  it('observes controls projected through spotFormBinding', async () => {
    await render({ projected: true, binding: true });
    host.control().markAsTouched();
    await fixture.whenStable();
    expectError(true);
  });

  it('follows controls replaced through formControlName', async () => {
    await render({ projected: true, named: true });
    const replacement = new FormControl('', { nonNullable: true, validators: (control) => Validators.required(control) });
    host.form.setControl('name', replacement);
    await fixture.whenStable();
    replacement.markAsTouched();
    await fixture.whenStable();
    expectError(true);
  });

  it('follows projected directives replaced or removed by control flow', async () => {
    await render({ projected: true, parentForm: false, replaceable: true });
    const subscribe = vi.spyOn(host.secondControl.events, 'subscribe');
    host.alternate.set(true);
    await fixture.whenStable();
    host.secondControl.markAsTouched();
    await fixture.whenStable();
    expectError(true);
    const subscriptions = subscribe.mock.results.filter((result) => result.type === 'return').map((result) => result.value);
    expect(subscriptions.length).toBeGreaterThan(0);
    host.showInput.set(false);
    await fixture.whenStable();
    expectError(false);
    expect(subscriptions.every((subscription) => subscription.closed)).toBe(true);
  });

  it('releases subscriptions when controls are replaced and the field is destroyed', async () => {
    await render({ parentForm: false });
    const replacement = new FormControl('', { nonNullable: true });
    const subscribe = vi.spyOn(replacement.events, 'subscribe');
    host.control.set(replacement);
    await fixture.whenStable();
    const subscriptions = subscribe.mock.results.filter((result) => result.type === 'return').map((result) => result.value);
    expect(subscriptions.length).toBeGreaterThan(0);
    expect(subscriptions.every((subscription) => !subscription.closed)).toBe(true);
    host.control.set(new FormControl('', { nonNullable: true }));
    await fixture.whenStable();
    expect(subscriptions.every((subscription) => subscription.closed)).toBe(true);
    host.control.set(replacement);
    await fixture.whenStable();
    const restored = subscribe.mock.results.at(-1)!;
    expect(restored.type).toBe('return');
    if (restored.type !== 'return') throw new Error('Subscription was not restored');
    expect(restored.value.closed).toBe(false);
    fixture.destroy();
    expect(restored.value.closed).toBe(true);
  });

  it('renders without a control or parent form', async () => {
    TestBed.configureTestingModule({
      imports: [CommonModule],
      declarations: [component],
      providers: [{ provide: I18nService, useValue: { t: (key:string) => key } }],
    });
    const field = TestBed.createComponent<SpotFormFieldComponent|SpotSelectorFieldComponent>(component);
    field.componentRef.setInput('label', 'Unbound');
    await field.whenStable();
    expect(field.nativeElement as HTMLElement).toHaveTextContent('Unbound');
    expect((field.nativeElement as HTMLElement).querySelector('.spot-form-field--errors')).not.toBeInTheDocument();
  });

  it('keeps validation hidden in never mode', async () => {
    await render();
    host.mode.set('never');
    await fixture.whenStable();
    host.control().markAsTouched();
    host.control().markAsDirty();
    await fixture.whenStable();
    expectError(false);
  });
});
