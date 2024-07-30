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
import { WpPreviewModalComponent } from 'core-app/shared/components/modals/preview-modal/wp-preview-modal/wp-preview.modal';

@Injectable({ providedIn: 'root' })
export class PreviewTriggerService {
  private modalElement:HTMLElement;

  private mouseInModal = false;

  constructor(
    readonly opModalService:OpModalService,
    readonly ngZone:NgZone,
    readonly injector:Injector,
  ) {
  }

  setupListener() {
    jQuery(document.body).on('mouseover', '.preview-trigger', (e) => {
      e.preventDefault();
      e.stopPropagation();
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const el = e.target as HTMLElement;
      if (el) {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        const href = el.getAttribute('href');

        if (!href) {
          return;
        }

        this.opModalService.show(
          WpPreviewModalComponent,
          this.injector,
          { workPackageLink: href, event: e },
          true,
        ).subscribe((previewModal) => {
          this.modalElement = previewModal.elementRef.nativeElement as HTMLElement;
          void previewModal.reposition(this.modalElement, el);
        });
      }
    });

    jQuery(document.body).on('mouseleave', '.preview-trigger', () => {
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseleave', '.op-wp-preview-modal', () => {
      this.mouseInModal = false;
      this.closeAfterTimeout();
    });

    jQuery(document.body).on('mouseenter', '.op-wp-preview-modal', () => {
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

  private isMouseOverPreview(e:JQuery.MouseLeaveEvent) {
    if (!this.modalElement) {
      return false;
    }

    const previewElement = jQuery(this.modalElement.children[0]);
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    if (previewElement && previewElement.offset()) {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      const horizontalHover = e.pageX >= Math.floor(previewElement.offset()!.left) && e.pageX < previewElement.offset()!.left + previewElement.width()!;
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      const verticalHover = e.pageY >= Math.floor(previewElement.offset()!.top) && e.pageY < previewElement.offset()!.top + previewElement.height()!;
      return horizontalHover && verticalHover;
    }
    return false;
  }
}
