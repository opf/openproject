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
  ChangeDetectionStrategy,
  ChangeDetectorRef, Component, ElementRef, OnInit, ViewChild,
} from '@angular/core';
import {
  ComponentPortal,
  ComponentType,
  PortalInjector,
} from '@angular/cdk/portal';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';

@Component({
  templateUrl: './modal-overlay.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpModalOverlayComponent implements OnInit {
  // override superclass
  // Allowing outside clicks to close the modal leads to the user involuntarily closing
  // the modal when removing error messages or clicking on labels e.g. in the registration modal.
  public closeOnOutsideClick = false;

  @ViewChild('portalOutlet') portalOutlet: ElementRef<HTMLElement>;

  modalPortal$ = this.modalService.activeModal$;

  constructor(
    readonly modalService:OpModalService,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
  ) { }

  ngOnInit():void {
    // onclose:
    // this.active.closingEvent.emit(this.active);
    // onopen:
    // this.active.onOpen();
    
    const portal = new ComponentPortal(modal, null, this.injectorFor(injector, locals));

    setTimeout(() => {
      // Focus on the first element
      this.active && this.active.onOpen();

      // Mark that we've opened the modal now
      this.opening = false;

      // Trigger another round of change detection in the modal
      ref.changeDetectorRef.detectChanges();
    }, 20);
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
