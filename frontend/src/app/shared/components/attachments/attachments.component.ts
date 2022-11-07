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
  Component, ElementRef, HostBinding, Input, OnInit, ViewChild,
} from '@angular/core';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { filter } from 'rxjs/operators';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import { UploadFile } from 'core-app/core/file-upload/op-file-upload.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';

function containsFiles(dataTransfer:DataTransfer):boolean {
  return dataTransfer.types.indexOf('Files') >= 0;
}

export const attachmentsSelector = 'op-attachments';

@Component({
  selector: attachmentsSelector,
  templateUrl: './attachments.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AttachmentsComponent extends UntilDestroyedMixin implements OnInit {
  @HostBinding('id.attachments_fields') public hostId = true;

  @HostBinding('class.op-attachments') public className = true;

  @Input('resource') public resource:HalResource;

  @Input() public allowUploading = true;

  @Input() public destroyImmediately = true;

  @ViewChild('hiddenFileInput') public filePicker:ElementRef<HTMLInputElement>;

  public draggingOver = false;

  public text = {
    attachments: this.I18n.t('js.label_attachments'),
    uploadLabel: this.I18n.t('js.label_add_attachments'),
    dropFiles: this.I18n.t('js.label_drop_files'),
    dropFilesHint: this.I18n.t('js.label_drop_files_hint'),
    foldersWarning: this.I18n.t('js.label_drop_folders_hint'),
  };

  public get hasAttachments() {
    return this.resource.attachments && this.resource.attachments.length;
  }

  constructor(
    public elementRef:ElementRef,
    protected readonly I18n:I18nService,
    protected readonly states:States,
    protected readonly halResourceService:HalResourceService,
    protected readonly attachmentsResourceService:AttachmentsResourceService,
    protected readonly toastService:ToastService,
  ) {
    super();

    populateInputsFromDataset(this);
  }

  ngOnInit() {
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
        console.log('new resource!', newResource);
        this.resource = newResource || this.resource;
      });
  }

  public triggerFileInput(event:MouseEvent):void {
    this.filePicker.nativeElement.click();

    event.preventDefault();
    event.stopPropagation();
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
    event.preventDefault();
    event.stopPropagation();

    const dfFiles = event.dataTransfer.files;
    const length:number = dfFiles ? dfFiles.length : 0;

    const files:UploadFile[] = [];
    for (let i = 0; i < length; i++) {
      files.push(dfFiles[i]);
    }

    this.uploadFiles(files);
    this.draggingOver = false;
  }

  public onDragOver(event:DragEvent):void {
    if (event.dataTransfer !== null && containsFiles(event.dataTransfer)) {
      // eslint-disable-next-line no-param-reassign
      event.dataTransfer.dropEffect = 'copy';
      this.draggingOver = true;
    }

    event.preventDefault();
    event.stopPropagation();
  }

  public onDragLeave(event:DragEvent):void {
    this.draggingOver = false;
    event.preventDefault();
    event.stopPropagation();
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
