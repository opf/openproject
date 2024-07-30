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
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnInit,
  Output,
  ViewChild,
} from '@angular/core';
import { BehaviorSubject, combineLatest, Observable } from 'rxjs';
import { distinctUntilChanged } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IPrincipal } from 'core-app/core/state/principals/principal.model';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { ConfirmDialogOptions } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';
import { getIconForMimeType } from 'core-app/shared/components/storages/functions/storages.functions';
import { IFileIcon } from 'core-app/shared/components/storages/icons.mapping';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-attachment-list-item]',
  templateUrl: './attachment-list-item.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpAttachmentListItemComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() public attachment:IAttachment;

  @Input() public index:number;

  @Input() public showTimestamp = true;

  @Output() public removeAttachment = new EventEmitter<void>();

  @ViewChild('avatar') avatar:ElementRef;

  static imageFileExtensions:string[] = ['jpeg', 'jpg', 'gif', 'bmp', 'png'];

  public text = {
    quarantinedHint: this.I18n.t('js.attachments.quarantined_hint'),
    dragHint: this.I18n.t('js.attachments.draggable_hint'),
    deleteTitle: this.I18n.t('js.attachments.delete'),
    deleteConfirmation: this.I18n.t('js.attachments.delete_confirmation'),
    removeFile: (arg:object):string => this.I18n.t('js.label_remove_file', arg),
  };

  public get deleteIconTitle():string {
    return this.text.removeFile({ fileName: this.attachment.fileName });
  }

  public author$:Observable<IPrincipal>;

  public timestampText:string;

  public fileIcon:IFileIcon;

  private viewInitialized$ = new BehaviorSubject<boolean>(false);

  constructor(
    private readonly I18n:I18nService,
    private readonly pathHelper:PathHelperService,
    private readonly timezoneService:TimezoneService,
    private readonly confirmDialogService:ConfirmDialogService,
    private readonly principalsResourceService:PrincipalsResourceService,
    private readonly principalRendererService:PrincipalRendererService,
  ) {
    super();
  }

  ngOnInit():void {
    this.fileIcon = getIconForMimeType(this.attachment.contentType);

    const href = this.attachment._links.author.href;
    this.author$ = this.principalsResourceService.requireEntity(href);

    this.timestampText = this.timezoneService.parseDatetime(this.attachment.createdAt).fromNow();

    combineLatest([
      this.author$,
      this.viewInitialized$.pipe(distinctUntilChanged()),
    ]).pipe(this.untilDestroyed())
      .subscribe(([user, initialized]) => {
        if (!initialized) {
          return;
        }

        this.principalRendererService.render(
          this.avatar.nativeElement,
          user,
          { hide: true, link: false },
          { hide: false, size: 'mini' },
        );
      });
  }

  ngAfterViewInit():void {
    this.viewInitialized$.next(true);
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
      el.textContent = this.attachment.fileName;
    } else {
      el = document.createElement('a');
      el.href = url;
      el.textContent = this.attachment.fileName;
    }

    return el;
  }

  private get downloadPath():string {
    return this.pathHelper.attachmentDownloadPath(String(this.attachment.id), this.attachment.fileName);
  }

  private get isImage():boolean {
    const ext = this.attachment.fileName.split('.').pop() || '';
    return OpAttachmentListItemComponent.imageFileExtensions.indexOf(ext.toLowerCase()) > -1;
  }

  public confirmRemoveAttachment():void {
    const options:ConfirmDialogOptions = {
      text: {
        text: this.text.deleteConfirmation,
        title: this.text.deleteTitle,
        button_continue: this.text.deleteTitle,
      },
      icon: {
        continue: 'delete',
      },
      dangerHighlighting: true,
    };
    void this.confirmDialogService
      .confirm(options)
      .then(() => { this.removeAttachment.emit(); })
      .catch(() => { /* confirmation rejected */ });
  }
}
