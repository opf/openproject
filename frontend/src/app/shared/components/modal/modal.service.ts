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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ComponentType, PortalInjector } from '@angular/cdk/portal';
import {
  Injectable,
  InjectionToken,
  Injector,
} from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { filter, take } from 'rxjs/operators';

import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { PortalOutletTarget } from 'core-app/shared/components/modal/portal-outlet-target.enum';

export const OpModalLocalsToken = new InjectionToken<never>('OP_MODAL_LOCALS');

export interface ModalData {
  modal:ComponentType<OpModalComponent>;
  injector:Injector;
  notFullscreen:boolean;
  mobileTopPosition:boolean;
  target:PortalOutletTarget;
}

@Injectable({ providedIn: 'root' })
export class OpModalService {
  public activeModalInstance$ = new BehaviorSubject<OpModalComponent|null>(null);

  public activeModalData$ = new BehaviorSubject<ModalData|null>(null);

  constructor(
    private readonly injector:Injector,
  ) {
    // Listen to keystrokes on window to close context menus
    window.addEventListener('keydown', (evt:KeyboardEvent) => {
      if (evt.key !== 'Escape' || evt.defaultPrevented) {
        return;
      }

      this.close();
    });
  }

  /**
   * Open a Modal reference and append it to the portal
   *
   * @param modal The modal component class to show
   * @param injector The injector to pass into the component. Ensure this is the hierarchical injector if needed.
   *                 Can be passed 'global' to take the default (global!) injector of this service.
   * @param locals A map to be injected via token into the component.
   * @param notFullscreen
   * @param mobileTopPosition
   * @param target An optional target override for the modal portal outlet
   */
  public show<T extends OpModalComponent>(
    modal:ComponentType<T>,
    injector:Injector|'global',
    locals:Record<string, unknown> = {},
    notFullscreen = false,
    mobileTopPosition = false,
    target = PortalOutletTarget.Default,
  ):Observable<T> {
    this.close();

    // Allow users to pass the global injector when deliberately requested.
    if (injector === 'global') {
      injector = this.injector;
    }

    this.activeModalData$.next({
      modal,
      injector: this.injectorFor(injector, locals),
      notFullscreen,
      mobileTopPosition,
      target,
    });

    return this.activeModalInstance$
      .pipe(
        filter((m) => m instanceof modal),
        take(1),
      ) as Observable<T>;
  }

  /**
   * Closes currently open modal window
   */
  public close():void {
    this.activeModalData$.next(null);
  }

  /**
   * Create an augmented injector that is equal to this service's injector + the additional data
   * passed into +show+.
   * This allows callers to pass data into the newly created modal.
   */
  private injectorFor(injector:Injector, data:Record<string, unknown>) {
    const injectorTokens = new WeakMap();
    // Pass the service because otherwise we're getting a cyclic dependency between the portal
    // host service and the bound portal
    data.service = this;

    injectorTokens.set(OpModalLocalsToken, data);

    return new PortalInjector(injector, injectorTokens);
  }
}
