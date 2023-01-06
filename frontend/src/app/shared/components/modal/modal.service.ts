// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import {
  Injectable,
  InjectionToken,
  Injector,
} from '@angular/core';
import { ComponentType, PortalInjector } from '@angular/cdk/portal';

import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { Observable, ReplaySubject } from 'rxjs';
import { filter, take } from 'rxjs/operators';

export const OpModalLocalsToken = new InjectionToken<any>('OP_MODAL_LOCALS');

@Injectable({ providedIn: 'root' })
export class OpModalService {
  public activeModalInstance$ = new ReplaySubject<OpModalComponent|null>(1);

  public activeModalData$ = new ReplaySubject<{
    modal:ComponentType<OpModalComponent>,
    injector:Injector,
    notFullscreen:boolean,
  }|null>(1);

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
   */
  public show<T extends OpModalComponent>(
    modal:ComponentType<T>,
    injector:Injector|'global',
    locals:Record<string, unknown> = {},
    notFullscreen = false,
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
    });

    return this.activeModalInstance$
      .pipe(
        filter((m) => m !== null),
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
