//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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

import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {Component, ElementRef, Input, ViewChild} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {OnInit} from '@angular/core';
import {UploadFile} from "core-components/api/op-file-upload/op-file-upload.service";
import {NotificationsService} from "core-app/modules/common/notifications/notifications.service";

@Component({
  selector: 'attachments-upload',
  templateUrl: './attachments-upload.html'
})
export class AttachmentsUploadComponent implements OnInit {
  @Input() public resource:HalResource;

  @ViewChild('hiddenFileInput') public filePicker:ElementRef;

  public draggingOver:boolean = false;
  public text:any;
  public maxFileSize:number;
  public $element:JQuery;

  constructor(readonly I18n:I18nService,
              readonly ConfigurationService:ConfigurationService,
              readonly notificationsService:NotificationsService,
              protected elementRef:ElementRef,
              protected halResourceService:HalResourceService) {
    this.text = {
      uploadLabel: I18n.t('js.label_add_attachments'),
      dropFiles: I18n.t('js.label_drop_files'),
      dropFilesHint: I18n.t('js.label_drop_files_hint'),
      foldersWarning: I18n.t('js.label_drop_folders_hint')
    };
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    this.ConfigurationService.initialized.then(() =>
      this.maxFileSize = this.ConfigurationService.maximumAttachmentFileSize
    );
  }

  public triggerFileInput(event:MouseEvent) {
    this.filePicker.nativeElement.click();

    event.preventDefault();
    event.stopPropagation();
    return false;
  }

  public onDropFiles(event:DragEvent) {
    event.dataTransfer!.dropEffect = 'copy';
    event.preventDefault();
    event.stopPropagation();

    let dfFiles = event.dataTransfer!.files;
    let length:number = dfFiles ? dfFiles.length : 0;

    let files:UploadFile[] = [];
    for (let i = 0; i < length; i++) {
      files.push(dfFiles[i]);
    }

    this.uploadFiles(files);
    this.draggingOver = false;
  }

  public onDragOver(event:DragEvent)  {
    if (this.containsFiles(event.dataTransfer)) {
      event.dataTransfer!.dropEffect = 'copy';
      this.draggingOver = true;
    }

    event.preventDefault();
    event.stopPropagation();
  }

  public onDragLeave(event:DragEvent)  {
    this.draggingOver = false;
    event.preventDefault();
    event.stopPropagation();
  }

  public onFilePickerChanged() {
    const files:UploadFile[] = Array.from(this.filePicker.nativeElement.files);
    this.uploadFiles(files);
  }

  private containsFiles(dataTransfer:any) {
    if (dataTransfer.types.contains) {
      return dataTransfer.types.contains('Files');
    } else {
      return (dataTransfer as DataTransfer).types.indexOf('Files') >= 0;
    }
  }

  protected uploadFiles(files:UploadFile[]):void {
    files = files || [];
    const countBefore = files.length;
    files = this.filterFolders(files);

    if (files.length === 0) {

      // If we filtered all files as directories, show a notice
      if (countBefore > 0) {
        this.notificationsService.addNotice(this.text.foldersWarning);
      }

      return;
    }

    this.resource.uploadAttachments(files);
  }

  /**
   * We try to detect folders by checking for either empty types
   * or empty file sizes.
   * @param files
   */
  protected filterFolders(files:UploadFile[]) {
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
