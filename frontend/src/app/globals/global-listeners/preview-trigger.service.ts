// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++


import {Injectable, Injector} from "@angular/core";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {WpPreviewModal} from "core-components/modals/preview-modal/wp-preview-modal/wp-preview.modal";
import {OpModalComponent} from "core-components/op-modals/op-modal.component";

@Injectable()
export class PreviewTriggerService {
  private previewModal:OpModalComponent;
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

      this.previewModal = this.opModalService.show(WpPreviewModal, this.injector, { workPackageLink: href });
      this.modalElement = this.previewModal.elementRef.nativeElement;
      jQuery(this.modalElement).position({
        my: 'left top',
        at: 'left bottom',
        of: el,
        collision: 'flipfit'
      });

      jQuery(this.modalElement).addClass('-no-width -no-height');
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

  private isMouseOverPreview(mev:JQuery.MouseLeaveEvent) {
    const previewElement = jQuery(this.modalElement.children[0]);
    if (previewElement && previewElement.offset()) {
      let horizontalHover = mev.pageX >= Math.floor(previewElement.offset()!.left) &&
                            mev.pageX < previewElement.offset()!.left + previewElement.width()!;
      let verticalHover = mev.pageY >= Math.floor(previewElement.offset()!.top) &&
                          mev.pageY < previewElement.offset()!.top + previewElement.height()!;
      return horizontalHover && verticalHover;
    }
    return false;
  }

}
