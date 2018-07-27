//-- copyright
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
//++

import {UploadFile} from '../../api/op-file-upload/op-file-upload.service';
import {ConfigurationService} from 'core-app/modules/common/config/configuration.service';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {Component, ElementRef, Input, ViewChild} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {HalResourceService} from 'core-app/modules/hal/services/hal-resource.service';
import {OnInit} from '@angular/core';

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
              protected elementRef:ElementRef,
              protected halResourceService:HalResourceService) {
    this.text = {
      uploadLabel: I18n.t('js.label_add_attachments'),
      dropFiles: I18n.t('js.label_drop_files'),
      dropFilesHint: I18n.t('js.label_drop_files_hint')
    };
  }

  ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    if (!this.resource) {
      // Parse the resource if any exists
      const source = this.$element.data('resource');
      this.resource = this.halResourceService.createHalResource(source, true);
    }

    this.ConfigurationService.api().then((settings:any) => {
      this.maxFileSize = settings.maximumAttachmentFileSize;
    });
  }

  public triggerFileInput(event:MouseEvent) {
    this.filePicker.nativeElement.click();

    event.preventDefault();
    event.stopPropagation();
    return false;
  }

  public onDropFiles(event:DragEvent) {
    event.dataTransfer.dropEffect = 'copy';
    event.preventDefault();
    event.stopPropagation();

    let dfFiles = event.dataTransfer.files;
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
      event.dataTransfer.dropEffect = 'copy';
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
      return dataTransfer.types.contains('Files')
    } else {
      return (dataTransfer as DataTransfer).types.indexOf('Files') >= 0;
    }
  }

  private uploadFiles(files:UploadFile[]):void {
    if (files === undefined || files.length === 0) {
      return;
    }

    this.resource.uploadAttachments(files);
  }
}
