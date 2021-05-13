//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++


import { Injectable, Injector } from "@angular/core";
import { OpModalService } from "core-app/modules/modal/modal.service";
import { WpPreviewModal } from "core-components/modals/preview-modal/wp-preview-modal/wp-preview.modal";

@Injectable({ providedIn: 'root' })
export class PreviewTriggerService {
  private previewModal:WpPreviewModal;
  private modalElement:HTMLElement;

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector) {
  }

  setupListener() {
    jQuery(document.body).on('mouseenter', '.preview-trigger', (e) => {
      e.preventDefault();
      e.stopPropagation();
      const el = jQuery(e.target);
      const href = el.attr('href');

      if (!href) {
        return;
      }

      this.previewModal = this.opModalService.show(
        WpPreviewModal,
        this.injector,
        { workPackageLink: href, event: e },
        true,
      );
      this.modalElement = this.previewModal.elementRef.nativeElement;
      this.previewModal.reposition(jQuery(this.modalElement), el);
    });

    jQuery(document.body).on('mouseleave', '.preview-trigger', (e:JQuery.MouseLeaveEvent) => {
      e.preventDefault();
      e.stopPropagation();

      if (this.isMouseOverPreview(e)) {
        jQuery(this.modalElement).on('mouseleave',  () => {
          this.opModalService.close();
        });
      } else {
        this.opModalService.close();
      }
    });
  }

  private isMouseOverPreview(e:JQuery.MouseLeaveEvent) {
    if (!this.modalElement) {
      return false;
    }

    const previewElement = jQuery(this.modalElement.children[0]);
    if (previewElement && previewElement.offset()) {
      const horizontalHover = e.pageX >= Math.floor(previewElement.offset()!.left) &&
                            e.pageX < previewElement.offset()!.left + previewElement.width()!;
      const verticalHover = e.pageY >= Math.floor(previewElement.offset()!.top) &&
                          e.pageY < previewElement.offset()!.top + previewElement.height()!;
      return horizontalHover && verticalHover;
    }
    return false;
  }

}
