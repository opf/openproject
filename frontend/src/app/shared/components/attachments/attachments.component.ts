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
  ChangeDetectorRef,
  Component,
  ElementRef,
  HostBinding,
  Input,
  OnDestroy,
  OnInit,
  ViewChild,
  ViewEncapsulation,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { filter, map, tap } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { UploadFile } from 'core-app/core/file-upload/op-file-upload.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { IAttachment } from 'core-app/core/state/attachments/attachment.model';
import { Observable } from 'rxjs';

function containsFiles(dataTransfer:DataTransfer):boolean {
  return dataTransfer.types.indexOf('Files') >= 0;
}

export const attachmentsSelector = 'op-attachments';

@Component({
  selector: attachmentsSelector,
  templateUrl: './attachments.component.html',
  encapsulation: ViewEncapsulation.None,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OpAttachmentsComponent extends UntilDestroyedMixin implements OnInit, OnDestroy {
  @HostBinding('attr.data-qa-selector') public qaSelector = 'op-attachments';

  @HostBinding('id.attachments_fields') public hostId = true;

  @HostBinding('class.op-file-section') public className = true;

  @Input() public resource:HalResource;

  @Input() public allowUploading = true;

  @Input() public destroyImmediately = true;

  public attachments$:Observable<IAttachment[]>;

  public draggingOverDropZone = false;

  public dragging = false;

  @ViewChild('hiddenFileInput') public filePicker:ElementRef<HTMLInputElement>;

  public text = {
    attachments: this.I18n.t('js.label_attachments'),
    uploadLabel: this.I18n.t('js.label_add_attachments'),
    dropFiles: this.I18n.t('js.label_drop_files'),
    dropFilesHint: this.I18n.t('js.label_drop_files_hint'),
    foldersWarning: this.I18n.t('js.label_drop_folders_hint'),
  };

  private get attachmentsSelfLink():string {
    const attachments = this.resource.attachments as unknown&{ href:string };
    return attachments.href;
  }

  private get collectionKey():string {
    return isNewResource(this.resource) ? 'new' : this.attachmentsSelfLink;
  }

  constructor(
    public elementRef:ElementRef,
    protected readonly I18n:I18nService,
    protected readonly states:States,
    protected readonly halResourceService:HalResourceService,
    protected readonly attachmentsResourceService:AttachmentsResourceService,
    protected readonly toastService:ToastService,
    protected readonly timezoneService:TimezoneService,
    protected readonly cdRef:ChangeDetectorRef,
  ) {
    super();

    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    if (!(this.resource instanceof HalResource)) {
      // Parse the resource if any exists
      this.resource = this.halResourceService.createHalResource(this.resource, true);
    }

    this.states.forResource(this.resource)!.changes$()
      .pipe(
        this.untilDestroyed(),
        filter((newResource) => !!newResource),
      )
      .subscribe((newResource:HalResource) => {
        this.resource = newResource || this.resource;
      });

    // ensure collection is loaded to the store
    if (!isNewResource(this.resource)) {
      this.attachmentsResourceService.requireCollection(this.attachmentsSelfLink);
    }

    const compareCreatedAtTimestamps = (a:IAttachment, b:IAttachment):number => {
      const rightCreatedAt = this.timezoneService.parseDatetime(b.createdAt);
      const leftCreatedAt = this.timezoneService.parseDatetime(a.createdAt);
      return rightCreatedAt.isBefore(leftCreatedAt) ? -1 : 1;
    };

    this.attachments$ = this
      .attachmentsResourceService
      .collection(this.collectionKey)
      .pipe(
        this.untilDestroyed(),
        map((attachments) => attachments.sort(compareCreatedAtTimestamps)),
        // store attachments for new resources directly into the resource. This way, the POST request to create the
        // resource embeds the attachments and the backend reroutes the anonymous attachments to the resource.
        tap((attachments) => {
          if (isNewResource(this.resource)) {
            this.resource.attachments = { elements: attachments.map((a) => a._links.self) };
          }
        }),
      );

    document.body.addEventListener('dragover', this.onGlobalDragOver.bind(this));
    document.body.addEventListener('dragleave', this.onGlobalDragEnd.bind(this));
    document.body.addEventListener('drop', this.onGlobalDragEnd.bind(this));
  }

  ngOnDestroy():void {
    document.body.removeEventListener('dragover', this.onGlobalDragOver.bind(this));
    document.body.removeEventListener('dragleave', this.onGlobalDragEnd.bind(this));
    document.body.removeEventListener('drop', this.onGlobalDragEnd.bind(this));
  }

  public triggerFileInput():void {
    this.filePicker.nativeElement.click();
  }

  public onFilePickerChanged():void {
    const fileList = this.filePicker.nativeElement.files;
    if (fileList === null) return;

    const files:UploadFile[] = Array.from(fileList);
    this.uploadFiles(files);
  }

  public onDropFiles(event:DragEvent):void {
    if (event.dataTransfer === null) return;

    // eslint-disable-next-line no-param-reassign
    event.dataTransfer.dropEffect = 'copy';

    const dfFiles = event.dataTransfer.files;
    const length:number = dfFiles ? dfFiles.length : 0;

    const files:UploadFile[] = [];
    for (let i = 0; i < length; i++) {
      files.push(dfFiles[i]);
    }

    this.uploadFiles(files);
    this.draggingOverDropZone = false;
    this.dragging = false;
  }

  public onDragOver(event:DragEvent):void {
    if (event.dataTransfer !== null && containsFiles(event.dataTransfer)) {
      // eslint-disable-next-line no-param-reassign
      event.dataTransfer.dropEffect = 'copy';
      this.draggingOverDropZone = true;
    }
  }

  public onDragLeave(_event:DragEvent):void {
    this.draggingOverDropZone = false;
  }

  public onGlobalDragEnd():void {
    this.dragging = false;

    this.cdRef.detectChanges();
  }

  public onGlobalDragOver():void {
    this.dragging = true;

    this.cdRef.detectChanges();
  }

  protected uploadFiles(files:UploadFile[]):void {
    let uploadFiles = files || [];
    const countBefore = files.length;
    uploadFiles = this.filterFolders(uploadFiles);

    if (uploadFiles.length === 0) {
      // If we filtered all files as directories, show a notice
      if (countBefore > 0) {
        this.toastService.addNotice(this.text.foldersWarning);
      }

      return;
    }

    this
      .attachmentsResourceService
      .attachFiles(this.resource, uploadFiles)
      .subscribe();
  }

  /**
   * We try to detect folders by checking for either empty types
   * or empty file sizes.
   * @param files
   */
  protected filterFolders(files:UploadFile[]):UploadFile[] {
    return files.filter((file) => {
      // Folders never have a mime type
      if (file.type !== '') {
        return true;
      }

      // Files however MAY have no mime type as well
      // so fall back to checking zero or 4096 bytes
      if (file.size === 0 || file.size === 4096) {
        console.warn(`Skipping file because of file size (${file.size}) %O`, file);
        return false;
      }

      return true;
    });
  }
}
