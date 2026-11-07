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

import {
  ApplicationRef,
  ComponentRef,
  createComponent,
  DestroyRef,
  inject,
  Injectable,
  Injector,
  inputBinding,
} from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { PrimerIconButtonComponent } from 'core-app/shared/components/primer/icon-button.component';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { DynamicIconName } from 'core-app/shared/components/primer/dynamic-icon-map';

/**
 * Owns the icon buttons mounted into fast-table rows. Rows are discarded
 * by plain DOM replacement, so buttons whose host left the document are
 * destroyed after every table render.
 */
@Injectable()
export class MountedTableActionButtons {
  private readonly appRef = inject(ApplicationRef);
  private readonly refs = new Set<ComponentRef<PrimerIconButtonComponent>>();

  constructor() {
    inject(IsolatedQuerySpace).tableRendered.values$()
      .pipe(takeUntilDestroyed())
      .subscribe(() => this.sweep());
    inject(DestroyRef).onDestroy(() => this.destroyAll());
  }

  get size():number {
    return this.refs.size;
  }

  mount(injector:Injector, icon:DynamicIconName, label:string, classes:string[] = []):HTMLElement {
    const ref = createComponent(PrimerIconButtonComponent, {
      environmentInjector: this.appRef.injector,
      elementInjector: injector,
      bindings: [
        inputBinding('icon', () => icon),
        inputBinding('scheme', () => 'invisible'),
        inputBinding('label', () => label),
        inputBinding('button-class', () => classes.join(' ')),
      ],
    });
    this.appRef.attachView(ref.hostView);
    ref.changeDetectorRef.detectChanges();
    this.refs.add(ref);

    return ref.location.nativeElement as HTMLElement;
  }

  sweep():void {
    this.refs.forEach((ref) => {
      if (!(ref.location.nativeElement as HTMLElement).isConnected) {
        ref.destroy();
        this.refs.delete(ref);
      }
    });
  }

  private destroyAll():void {
    this.refs.forEach((ref) => ref.destroy());
    this.refs.clear();
  }
}
