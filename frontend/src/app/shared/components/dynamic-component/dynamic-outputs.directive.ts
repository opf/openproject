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
import { ChangeDetectorRef, Directive, DoCheck, inject, input, OnDestroy, reflectComponentType } from '@angular/core';
import { Unsubscribable } from 'rxjs';

export type DynamicOutputs = Record<string, (event:never) => unknown>;

interface DynamicOutput {
  subscribe(callback:(event:unknown) => void):Unsubscribable;
}

function isOutput(value:unknown):value is DynamicOutput {
  return typeof value === 'object' && value !== null && 'subscribe' in value && typeof value.subscribe === 'function';
}

@Directive({
  selector: '[ngComponentOutlet][opDynamicOutputs]',
})
export class DynamicOutputsDirective implements DoCheck, OnDestroy {
  readonly opDynamicOutputs = input<DynamicOutputs|undefined>();

  private readonly outlet:NgComponentOutlet<unknown> = inject(NgComponentOutlet, { self: true });
  private readonly changeDetector = inject(ChangeDetectorRef);
  private readonly subscriptions = new Map<string, { output:DynamicOutput; subscription:Unsubscribable }>();
  private handlers = new Map<string, DynamicOutputs[string]>();
  private instance:unknown;

  ngDoCheck() {
    const instance = this.outlet.componentInstance;
    if (instance !== this.instance) {
      this.disconnect();
      this.instance = instance;
    }
    const component = this.outlet.ngComponentOutlet;
    const aliases = component ? reflectComponentType(component)?.outputs ?? [] : [];
    this.handlers = new Map(Object.entries(this.opDynamicOutputs() ?? {}).map(([name, handler]) => [
      aliases.find((output) => output.templateName === name)?.propName ?? name,
      handler,
    ]));

    const outputs = new Map<string, DynamicOutput>();
    if (typeof instance === 'object' && instance !== null) {
      for (const name of this.handlers.keys()) {
        const candidate:unknown = Reflect.get(instance, name);
        if (isOutput(candidate)) outputs.set(name, candidate);
      }
    }

    for (const [name, binding] of this.subscriptions) {
      if (outputs.get(name) !== binding.output) {
        binding.subscription.unsubscribe();
        this.subscriptions.delete(name);
      }
    }
    for (const [name, output] of outputs) {
      if (!this.subscriptions.has(name)) {
        const subscription = output.subscribe((event) => {
          this.changeDetector.markForCheck();
          this.handlers.get(name)?.(event as never);
        });
        this.subscriptions.set(name, { output, subscription });
      }
    }
  }

  ngOnDestroy() {
    this.disconnect();
    this.handlers.clear();
  }

  private disconnect() {
    for (const { subscription } of this.subscriptions.values()) subscription.unsubscribe();
    this.subscriptions.clear();
  }
}
