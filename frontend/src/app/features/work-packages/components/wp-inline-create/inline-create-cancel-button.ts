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

import { ApplicationRef, ComponentRef, createComponent, Injector, inputBinding, outputBinding } from '@angular/core';
import { PrimerIconButtonComponent } from 'core-app/shared/components/primer/icon-button.component';

export const inlineCreateCancelClassName = 'wp-table--cancel-create-link';

/**
 * The Cancel control of an inline-create row. Row builders are recreated on
 * every refresh and rebuild cells imperatively, so the mounted button lives
 * here and builders only move its element into the cell that hosts it.
 */
export class InlineCreateCancelButton {
  readonly element:HTMLElement;

  private readonly ref:ComponentRef<PrimerIconButtonComponent>;

  constructor(injector:Injector, label:string, onCancel:() => void) {
    const appRef = injector.get(ApplicationRef);
    this.ref = createComponent(PrimerIconButtonComponent, {
      environmentInjector: appRef.injector,
      elementInjector: injector,
      bindings: [
        inputBinding('icon', () => 'x'),
        inputBinding('scheme', () => 'invisible'),
        inputBinding('label', () => label),
        outputBinding('clicked', onCancel),
      ],
    });
    this.element = this.ref.location.nativeElement as HTMLElement;
    this.element.classList.add(inlineCreateCancelClassName);

    appRef.attachView(this.ref.hostView);
    this.ref.changeDetectorRef.detectChanges();
  }

  destroy():void {
    this.ref.destroy();
  }
}
