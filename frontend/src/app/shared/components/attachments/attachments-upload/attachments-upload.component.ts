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
  ElementRef,
  Input,
  OnInit,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { UploadFile } from 'core-app/core/file-upload/op-file-upload.service';
import { AttachmentsResourceService } from 'core-app/core/state/attachments/attachments.service';

@Component({
  selector: 'op-attachments-upload',
  templateUrl: './attachments-upload.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AttachmentsUploadComponent implements OnInit {
  @Input() public resource:HalResource;

  @ViewChild('hiddenFileInput') public filePicker:ElementRef<HTMLInputElement>;

  public draggingOver = false;

  public text = {
    uploadLabel: this.I18n.t('js.label_add_attachments'),
    dropFiles: this.I18n.t('js.label_drop_files'),
    dropFilesHint: this.I18n.t('js.label_drop_files_hint'),
    foldersWarning: this.I18n.t('js.label_drop_folders_hint'),
  };

  public maxFileSize:number;

  public $element:JQuery;

  constructor(readonly I18n:I18nService,
    private readonly attachmentsResourceService:AttachmentsResourceService,
    readonly configurationService:ConfigurationService,
    readonly toastService:ToastService,
    protected elementRef:ElementRef,
    protected halResourceService:HalResourceService) { }

  ngOnInit():void {
    this.$element = jQuery<HTMLElement>(this.elementRef.nativeElement);

    void this.configurationService.initialized.then(() => {
      this.maxFileSize = this.configurationService.maximumAttachmentFileSize as number;
    });
  }

  public triggerFileInput(event:MouseEvent):boolean {
    this.filePicker.nativeElement.click();

    event.preventDefault();
    event.stopPropagation();
    return false;
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
    if (event.dataTransfer !== null && AttachmentsUploadComponent.containsFiles(event.dataTransfer)) {
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

  public onFilePickerChanged():void {
    const fileList = this.filePicker.nativeElement.files;
    if (fileList === null) return;

    const files:UploadFile[] = Array.from(fileList);
    this.uploadFiles(files);
  }

  private static containsFiles(dataTransfer:DataTransfer):boolean {
    return dataTransfer.types.indexOf('Files') >= 0;
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
