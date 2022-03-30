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
  ChangeDetectionStrategy, Component, EventEmitter, Input, OnInit, Output,
} from '@angular/core';
import { Observable, of } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { IUser } from 'core-app/core/state/principals/user.model';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

@Component({
  selector: 'op-attachment-list-item',
  templateUrl: './attachment-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AttachmentListItemComponent implements OnInit {
  @Input() public resource:HalResource;

  @Input() public attachment:IAttachment;

  @Input() public index:number;

  @Input() destroyImmediately = true;

  @Output() public removeAttachment = new EventEmitter<void>();

  static imageFileExtensions:string[] = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public text = {
    dragHint: this.I18n.t('js.attachments.draggable_hint'),
    destroyConfirmation: this.I18n.t('js.text_attachment_destroy_confirmation'),
    removeFile: (arg:unknown):string => this.I18n.t('js.label_remove_file', arg),
  };

  public get deleteIconTitle():string {
    return this.text.removeFile({ fileName: this.attachment.fileName });
  }

  public author$:Observable<IUser>;

  constructor(private readonly principalsResourceService:PrincipalsResourceService,
    private readonly I18n:I18nService,
    private readonly pathHelper:PathHelperService) {
  }

  ngOnInit():void {
    const authorId = idFromLink(this.attachment._links.author.href);

    this.author$ = this.principalsResourceService.query.selectEntity(authorId)
      .pipe(
        switchMap((user) => (user ? of(user) : this.principalsResourceService.fetchUser(authorId))),
        map((user) => user as IUser),
      );
  }

  /**
   * Set the appropriate data for drag & drop of an attachment item.
   * @param evt DragEvent
   */
  public setDragData(evt:DragEvent):void {
    const url = this.downloadPath;
    const previewElement = this.draggableHTML(url);

    if (evt.dataTransfer == null) return;

    evt.dataTransfer.setData('text/plain', url);
    evt.dataTransfer.setData('text/html', previewElement.outerHTML);
    evt.dataTransfer.setData('text/uri-list', url);
    evt.dataTransfer.setDragImage(previewElement, 0, 0);
  }

  public draggableHTML(url:string):HTMLImageElement|HTMLAnchorElement {
    let el:HTMLImageElement|HTMLAnchorElement;

    if (this.isImage) {
      el = document.createElement('img');
      el.src = url;
      el.textContent = this.fileName;
    } else {
      el = document.createElement('a');
      el.href = url;
      el.textContent = this.fileName;
    }

    return el;
  }

  public get downloadPath():string {
    return this.pathHelper.attachmentDownloadPath(String(this.attachment.id), this.fileName);
  }

  public get isImage():boolean {
    const ext = this.fileName.split('.').pop() || '';
    return AttachmentListItemComponent.imageFileExtensions.indexOf(ext.toLowerCase()) > -1;
  }

  public get fileName():string {
    return this.attachment.fileName;
  }

  public confirmRemoveAttachment($event:JQuery.TriggeredEvent):boolean {
    if (!window.confirm(this.text.destroyConfirmation)) {
      $event.stopImmediatePropagation();
      $event.preventDefault();
      return false;
    }

    this.removeAttachment.emit();
    return false;
  }
}
