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
  Component,
  ComponentRef,
  OnInit,
  ViewChild,
} from '@angular/core';
import {
  CdkPortalOutlet,
  ComponentPortal,
} from '@angular/cdk/portal';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpModalComponent } from './modal.component';
import { ReplaySubject } from 'rxjs';

export const opModalOverlaySelector = 'op-modal-overlay';

@Component({
  selector: opModalOverlaySelector,
  templateUrl: './modal-overlay.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpModalOverlayComponent implements OnInit {
  public notFullscreen = false;

  @ViewChild(CdkPortalOutlet) portalOutlet:CdkPortalOutlet;

  activeModalData$ = this.modalService.activeModalData$;
  activeModalInstance$ = this.modalService.activeModalInstance$;
  activeModalRef$ = new ReplaySubject<OpModalComponent|null>();

  constructor(
    readonly modalService:OpModalService,
    readonly I18n:I18nService,
  ) { }

  ngOnInit():void {
    this.activeModalData$
    .subscribe((modalData) => {
      this.notFullscreen = false;

      if (modalData === null) {
        const ref = (this.portalOutlet.attachedRef as ComponentRef<OpModalComponent>);
        if (!ref) {
          return;
        }

        if (!ref.instance.onClose()) {
          return;
        }
        
        ref.instance.closingEvent.emit(ref.instance);
        this.activeModalRef$.next(null);
        this.activeModalInstance$.next(null);

        this.portalOutlet.detach();

        return;
      }

      const {
        modal,
        injector,
        notFullscreen,
      } = modalData;
      this.notFullscreen = notFullscreen;
      const portal = new ComponentPortal(modal, null, injector);
      const ref = this.portalOutlet.attach(portal);
      const instance = ref.instance;
      this.activeModalRef$.next(instance);

      this.activeModalInstance$.next(instance);
      setTimeout(() => {
        // Focus on the first element
        instance && instance.onOpen();

        // Trigger another round of change detection in the modal
        ref.changeDetectorRef.detectChanges();
      }, 0);
    });
  }

  public close() {
    this.modalService.close();
  }
}
