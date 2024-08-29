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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ComponentRef,
  ElementRef,
  ViewChild,
} from '@angular/core';
import { CdkPortalOutlet, ComponentPortal } from '@angular/cdk/portal';
import { combineLatest } from 'rxjs';
import { distinctUntilChanged, filter } from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { ModalData, OpModalService } from 'core-app/shared/components/modal/modal.service';
import { PortalOutletTarget } from 'core-app/shared/components/modal/portal-outlet-target.enum';


@Component({
  selector: 'opce-modal-overlay',
  templateUrl: './modal-overlay.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpModalOverlayComponent {
  public notFullscreen = false;

  mobileTopPosition = false;

  public portalOutlet:CdkPortalOutlet;

  @ViewChild(CdkPortalOutlet) set portalOutletContainer(v:CdkPortalOutlet) {
    // ViewChild reference may be undefined initially
    // due to ngIf
    if (v !== undefined) {
      this.portalOutlet = v;
      this.setupListener();
    }
  }

  @ViewChild('overlay', { static: true }) overlay:ElementRef;

  activeModalData$ = this.modalService.activeModalData$;

  activeModalInstance$ = this.modalService.activeModalInstance$;

  constructor(
    readonly modalService:OpModalService,
    readonly I18n:I18nService,
    readonly cdRef:ChangeDetectorRef,
  ) {
  }

  setupListener():void {
    combineLatest([
      this.activeModalInstance$,
      // multiple 'closing' events in a row are squashed
      this.activeModalData$.pipe(distinctUntilChanged(), filter(this.isDefaultTarget.bind(this))),
    ])
      .subscribe(([instance, data]) => {
        if (instance === null && data === null) {
          // do nothing
          return;
        }

        if (instance !== null && data === null) {
          this.detachPortalInstance();
          return;
        }

        if (instance === null && data !== null) {
          this.createAndAttachPortalInstance(data);
        }
      });
  }

  protected isDefaultTarget(modalData:ModalData|null):boolean {
    if (modalData === null) return true;

    return modalData.target === PortalOutletTarget.Default;
  }

  public close($event:MouseEvent, includeChildClicks = true):void {
    if (!includeChildClicks && $event.currentTarget !== $event.target) {
      return;
    }
    this.modalService.close();
  }

  private detachPortalInstance():void {
    const ref = (this.portalOutlet.attachedRef as ComponentRef<OpModalComponent>);
    if (!ref) {
      return;
    }

    if (!ref.instance.onClose()) {
      return;
    }

    ref.instance.closingEvent.emit(ref.instance);
    this.portalOutlet.detach();
    this.modalService.activeModalInstance$.next(null);
  }

  private createAndAttachPortalInstance(data:ModalData):void {
    const { modal, injector, notFullscreen, mobileTopPosition } = data;
    this.notFullscreen = notFullscreen;
    this.mobileTopPosition = mobileTopPosition;
    const portal = new ComponentPortal(modal, null, injector);
    const ref = this.portalOutlet.attach(portal);
    const instance = ref.instance;

    this.modalService.activeModalInstance$.next(instance);
    this.cdRef.detectChanges();

    // Focus on wrapper by default
    (this.overlay.nativeElement as HTMLElement).focus();

    // Focus on the first element
    instance && instance.onOpen();
  }
}
