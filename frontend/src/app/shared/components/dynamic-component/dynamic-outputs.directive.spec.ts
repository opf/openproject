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

import { NgComponentOutlet } from '@angular/common';
import { AfterViewInit, ChangeDetectorRef, Component, EventEmitter, inject, InjectionToken, Injector, input, OnInit, output, Output, signal, Type, viewChild } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DynamicOutputs, DynamicOutputsDirective } from './dynamic-outputs.directive';

const context = new InjectionToken<string>('outlet test context', { factory: () => 'default' });

@Component({
  template: '<button (click)="changed.emit(label())">{{ label() }} {{ context }}</button>',
})
class ChildComponent implements OnInit, AfterViewInit {
  readonly label = input('first');
  readonly context = inject(context);
  // eslint-disable-next-line @angular-eslint/no-output-rename -- The adapter must resolve public output aliases.
  @Output('accepted') readonly changed = new EventEmitter<string>();
  @Output() readonly initialized = new EventEmitter<string>();
  readonly modern = output<string>();

  ngOnInit() { this.initialized.emit('init'); }

  ngAfterViewInit() { this.initialized.emit('view'); }
}

@Component({ template: '<p>replacement</p>' })
class ReplacementComponent extends ChildComponent {}

@Component({
  imports: [DynamicOutputsDirective, NgComponentOutlet],
  template: `
    <span>{{ last }}</span>
    <ng-container [ngComponentOutlet]="component()" [ngComponentOutletInputs]="inputs()"
      [ngComponentOutletInjector]="injector" [opDynamicOutputs]="handlers()" />
  `,
})
class HostComponent {
  readonly changeDetector = inject(ChangeDetectorRef);
  readonly component = signal<Type<ChildComponent>|null>(ChildComponent);
  readonly inputs = signal<Record<string, unknown>>({ label: 'first' });
  readonly injector = Injector.create({ providers: [{ provide: context, useValue: 'custom' }], parent: inject(Injector) });
  readonly outlet = viewChild.required<NgComponentOutlet<ChildComponent>>(NgComponentOutlet);
  readonly events:string[] = [];
  last = 'nothing';
  readonly handlers = signal<DynamicOutputs|undefined>({
    accepted: (value:string) => { this.last = value; },
    initialized: (phase:string) => this.events.push(phase),
    modern: (value:string) => { this.last = value; },
    absent: () => { this.last = 'unexpected'; },
  });
}

describe('DynamicOutputsDirective', () => {
  let fixture:ComponentFixture<HostComponent>;
  let host:HostComponent;

  async function render() {
    fixture = TestBed.createComponent(HostComponent);
    host = fixture.componentInstance;
    await fixture.whenStable();
  }

  const child = () => host.outlet().componentInstance!;
  const text = () => (fixture.nativeElement as HTMLElement).querySelector('span')!.textContent;

  it.each([true, false])('captures initialization outputs with outlet imported first: %s', async (outletFirst) => {
    TestBed.overrideComponent(HostComponent, { set: {
      imports: outletFirst ? [NgComponentOutlet, DynamicOutputsDirective] : [DynamicOutputsDirective, NgComponentOutlet],
    } });
    await render();
    expect(host.events).toEqual(['init', 'view']);
    host.component.set(ReplacementComponent);
    await fixture.whenStable();
    expect(host.events).toEqual(['init', 'view', 'init', 'view']);
  });

  it('renders inputs and a custom injector while delivering aliased outputs to an OnPush parent', async () => {
    await render();
    expect((fixture.nativeElement as HTMLElement).querySelector('button')).toHaveTextContent('first custom');
    host.inputs.set({ label: 'second' });
    await fixture.whenStable();
    expect((fixture.nativeElement as HTMLElement).querySelector('button')).toHaveTextContent('second custom');
    await Promise.resolve();
    child().changed.emit('accepted asynchronously');
    await fixture.whenStable();
    expect(text()).toBe('accepted asynchronously');
  });

  it('delivers signal-based outputs', async () => {
    await render();
    child().modern.emit('modern');
    await fixture.whenStable();
    expect(text()).toBe('modern');
  });

  it('uses replacement callbacks without duplicating subscriptions', async () => {
    await render();
    const original = child();
    const received:string[] = [];
    host.handlers.set({ accepted: (value:string) => received.push(`new:${value}`) });
    await fixture.whenStable();
    original.changed.emit('one');
    expect(received).toEqual(['new:one']);
    expect(host.last).toBe('nothing');
  });

  it('reconciles additions and removals in the same callback map', async () => {
    await render();
    const handlers = host.handlers()!;
    delete handlers.accepted;
    handlers.changed = (value:string) => { host.last = value; };
    host.changeDetector.markForCheck();
    await fixture.whenStable();
    child().changed.emit('property fallback');
    await fixture.whenStable();
    expect(text()).toBe('property fallback');
    delete handlers.changed;
    host.changeDetector.markForCheck();
    await fixture.whenStable();
    child().changed.emit('ignored');
    expect(host.last).toBe('property fallback');
  });

  it('disconnects replaced and removed children', async () => {
    await render();
    const original = child();
    host.component.set(ReplacementComponent);
    await fixture.whenStable();
    original.changed.emit('old');
    expect(host.last).toBe('nothing');
    const replacement = child();
    replacement.changed.emit('new');
    await fixture.whenStable();
    expect(text()).toBe('new');
    host.component.set(null);
    await fixture.whenStable();
    replacement.changed.emit('removed');
    expect(host.last).toBe('new');
  });

  it('disconnects when the output map is removed or the host is destroyed', async () => {
    await render();
    const original = child();
    const handlers = host.handlers();
    host.handlers.set(undefined);
    await fixture.whenStable();
    original.changed.emit('removed map');
    expect(host.last).toBe('nothing');
    host.handlers.set(handlers);
    await fixture.whenStable();
    fixture.destroy();
    original.changed.emit('destroyed');
    expect(host.last).toBe('nothing');
  });
});
