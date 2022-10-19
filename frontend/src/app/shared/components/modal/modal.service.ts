// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
  ApplicationRef,
  ComponentFactoryResolver,
  ComponentRef,
  Injectable,
  InjectionToken,
  Injector,
} from '@angular/core';
import {
  ComponentPortal,
  ComponentType,
  PortalInjector,
} from '@angular/cdk/portal';
import { TransitionService } from '@uirouter/core';

import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { ReplaySubject } from 'rxjs';
import { take } from 'rxjs/operators';

export const OpModalLocalsToken = new InjectionToken<any>('OP_MODAL_LOCALS');

@Injectable({ providedIn: 'root' })
export class OpModalService {
  public activeModal$ = new ReplaySubject<ComponentPortal<OpModalComponent>|null>();

  constructor(
    private readonly componentFactoryResolver:ComponentFactoryResolver,
    private readonly appRef:ApplicationRef,
    private readonly $transitions:TransitionService,
    private readonly injector:Injector,
  ) {
    const hostElement = document.createElement('div');
    hostElement.classList.add('spot-modal-overlay');
    document.body.appendChild(hostElement);

    // Listen to keystrokes on window to close context menus
    window.addEventListener('keydown', (evt:KeyboardEvent) => {
      if (evt.key !== 'Escape') {
        return;
      }

      this.activeModal$.pipe(take(1)).subscribe((activeModal) => {
        if (activeModal) {
          this.activeModal$.next(null);
        }
      });
    });
  }

  /**
   * Open a Modal reference and append it to the portal
   *
   * @param modal The modal component class to show
   * @param injector The injector to pass into the component. Ensure this is the hierarchical injector if needed.
   *                 Can be passed 'global' to take the default (global!) injector of this service.
   * @param locals A map to be injected via token into the component.
   * @param notFullScreen Whether the modal is treated as non-overlay
   */
  public show<T extends OpModalComponent>(
    modal:ComponentType<T>,
    injector:Injector|'global',
    locals:Record<string, unknown> = {},
    notFullScreen = false,
  ):T {
    this.close();

    // Prevent closing events during the opening time frame.
    this.opening = true;

    // Allow users to pass the global injector when deliberately requested.
    if (injector === 'global') {
      injector = this.injector;
    }

    // Create a portal for the given component class and render it
    const portal = new ComponentPortal(modal, null, this.injectorFor(injector, locals));

    setTimeout(() => {
      // Focus on the first element
      this.active && this.active.onOpen();

      // Mark that we've opened the modal now
      this.opening = false;

      // Trigger another round of change detection in the modal
      ref.changeDetectorRef.detectChanges();
    }, 20);

    return this.active as T;
  }

  public isActive(modal:OpModalComponent):boolean {
    return this.active !== null && this.active === modal;
  }

  /**
   * Closes currently open modal window
   */
  public close():void {
    // Detach any component currently in the portal
    this.activeModal$.next(null);
    /*
    if (this.active && this.active.onClose()) {
      this.active.closingEvent.emit(this.active);
      this.bodyPortalHost.detach();
      this.portalHostElement.classList.remove('spot-modal-overlay_active');
      this.portalHostElement.classList.remove('spot-modal-overlay_not-full-screen');
      this.active = null;
    }
    */
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
