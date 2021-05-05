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
import { Component, ElementRef, OnInit, ViewChild } from "@angular/core";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { OpenProjectFileUploadService , UploadFile } from "core-components/api/op-file-upload/op-file-upload.service";
import { NotificationsService } from "core-app/modules/common/notifications/notifications.service";

import { ImageHelpers } from "core-app/helpers/images/resizer";

@Component({
  selector: 'avatar-upload-form',
  templateUrl: './avatar-upload-form.html'
})
export class AvatarUploadFormComponent implements OnInit {
  // Form targets
  public form:any;
  public target:string;
  public method:string;

  // File
  public avatarFile:any;
  public avatarPreviewUrl:any;
  public busy = false;
  public fileInvalid = false;

  @ViewChild('avatarFilePicker', { static: true }) public avatarFilePicker:ElementRef;

  // Text
  public text = {
    label_choose_avatar: this.I18n.t('js.avatars.label_choose_avatar'),
    upload_instructions: this.I18n.t('js.avatars.text_upload_instructions'),
    error_too_large: this.I18n.t('js.avatars.error_image_too_large'),
    wrong_file_format: this.I18n.t('js.avatars.wrong_file_format'),
    button_update: this.I18n.t('js.button_update'),
    uploading: this.I18n.t('js.avatars.uploading_avatar'),
    preview: this.I18n.t('js.label_preview')
  };

  public constructor(protected I18n:I18nService,
                     protected elementRef:ElementRef,
                     protected notificationsService:NotificationsService,
                     protected opFileUpload:OpenProjectFileUploadService) {
  }

  public ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.target = element.getAttribute('target');
    this.method = element.getAttribute('method');
  }

  public onFilePickerChanged(_evt:Event) {
    const files:UploadFile[] = Array.from(this.avatarFilePicker.nativeElement.files);
    if (files.length === 0) {
      return;
    }

    const file = files[0];
    if (['image/jpeg', 'image/png', 'image/gif'].indexOf(file.type) === -1) {
      this.fileInvalid = true;
      return;
    }

    ImageHelpers.resizeFile(128, file).then(([dataURL, blob]) => {
      // Create resized file
      blob.name = file.name;
      this.avatarFile = blob;
      this.avatarPreviewUrl = dataURL;
    });
  }

  public uploadAvatar(evt:Event) {
    evt.preventDefault();
    this.busy = true;
    const upload = this.opFileUpload.uploadSingle(this.target, this.avatarFile, this.method, 'text');
    this.notificationsService.addAttachmentUpload(this.text.uploading, [upload]);

    upload[1].subscribe(
      (evt:any) => {
        switch (evt.type) {
        case 0: // Sent
          return;

        case 4:
          this.avatarFile.progress = 100;
          this.busy = false;
          window.location.reload();
          return;

        default:
          // Sent or unknown event
          return;
        }
      },
      (error:any) => {
        this.notificationsService.addError(error.error);
        this.busy = false;
      }
    );
  }
}
