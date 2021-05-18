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

import { Component, EventEmitter, Input, Output } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { States } from 'core-components/states.service';
import { HalResourceNotificationService } from "core-app/modules/hal/services/hal-resource-notification.service";

@Component({
  selector: 'attachment-list-item',
  templateUrl: './attachment-list-item.html'
})
export class AttachmentListItemComponent {
  @Input() public resource:HalResource;
  @Input() public attachment:any;
  @Input() public index:any;
  @Input() destroyImmediately = true;

  @Output() public removeAttachment = new EventEmitter<void>();

  static imageFileExtensions:string[] = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public text = {
    dragHint: this.I18n.t('js.attachments.draggable_hint'),
    destroyConfirmation: this.I18n.t('js.text_attachment_destroy_confirmation'),
    removeFile: (arg:any) => this.I18n.t('js.label_remove_file', arg)
  };

  constructor(protected halNotification:HalResourceNotificationService,
              readonly I18n:I18nService,
              readonly states:States,
              readonly pathHelper:PathHelperService) {
  }

  /**
   * Set the appropriate data for drag & drop of an attachment item.
   * @param evt DragEvent
   */
  public setDragData(evt:DragEvent) {
    const url = this.downloadPath;
    const previewElement = this.draggableHTML(url);

    evt.dataTransfer!.setData("text/plain", url);
    evt.dataTransfer!.setData("text/html", previewElement.outerHTML);
    evt.dataTransfer!.setData("text/uri-list", url);
    evt.dataTransfer!.setDragImage(previewElement, 0, 0);
  }

  public draggableHTML(url:string) {
    let el:HTMLImageElement|HTMLAnchorElement;

    if (this.isImage) {
      el = document.createElement('img') as HTMLImageElement;
      el.src = url;
      el.textContent = this.fileName;
    } else {
      el = document.createElement('a') as HTMLAnchorElement;
      el.href = url;
      el.textContent = this.fileName;
    }

    return el;
  }

  public get downloadPath() {
    return this.pathHelper.attachmentDownloadPath(this.attachment.id, this.fileName);
  }

  public get isImage() {
    const ext = this.fileName.split('.').pop() || '';
    return AttachmentListItemComponent.imageFileExtensions.indexOf(ext.toLowerCase()) > -1;
  }

  public get fileName() {
    const a = this.attachment;
    return a.fileName || a.customName || a.name;
  }

  public confirmRemoveAttachment($event:JQuery.TriggeredEvent) {
    if (!window.confirm(this.text.destroyConfirmation)) {
      $event.stopImmediatePropagation();
      $event.preventDefault();
      return false;
    }

    this.removeAttachment.emit();

    if (this.destroyImmediately) {
      this
        .resource
        .removeAttachment(this.attachment);
    }

    return false;
  }
}
