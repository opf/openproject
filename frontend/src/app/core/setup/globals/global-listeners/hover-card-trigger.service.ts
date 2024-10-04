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

import { Injectable, Injector, NgZone } from '@angular/core';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { HoverCardComponent } from 'core-app/shared/components/modals/preview-modal/hover-card-modal/hover-card.modal';

@Injectable({ providedIn: 'root' })
export class HoverCardTriggerService {
  private modalElement:HTMLElement;

  private mouseInModal = false;

  constructor(
    readonly opModalService:OpModalService,
    readonly ngZone:NgZone,
    readonly injector:Injector,
  ) {
  }

  setupListener() {
    jQuery(document.body).on('mouseover', '.op-hover-card--preview-trigger', (e) => {
      e.preventDefault();
      e.stopPropagation();
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const el = e.target as HTMLElement;
      if (el) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        const turboFrameUrl = el.getAttribute('data-hover-card-url');

        if (!turboFrameUrl) {
          return;
        }

        this.opModalService.show(
          HoverCardComponent,
          this.injector,
          { turboFrameSrc: turboFrameUrl, event: e },
          true,
        ).subscribe((previewModal) => {
          this.modalElement = previewModal.elementRef.nativeElement as HTMLElement;
          void previewModal.reposition(this.modalElement, el);
        });
      }
    });

    jQuery(document.body).on('mouseleave', '.op-hover-card--preview-trigger', () => {
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseleave', '.op-hover-card', () => {
      this.mouseInModal = false;
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseenter', '.op-hover-card', () => {
      this.mouseInModal = true;
    });
  }

  private closeAfterTimeout() {
    this.ngZone.runOutsideAngular(() => {
      setTimeout(() => {
        if (!this.mouseInModal) {
          this.opModalService.close();
        }
      }, 100);
    });
  }
}
