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

import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit, ViewChild, } from '@angular/core';

import { resizeFile } from 'core-app/shared/helpers/images/resizer';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { OpUploadService } from 'core-app/core/upload/upload.service';

import { AvatarUploadFile, AvatarUploadService } from '../avatar-upload.service';
import { HttpErrorResponse } from '@angular/common/http';

@Component({
  selector: 'opce-avatar-upload-form',
  templateUrl: './avatar-upload-form.html',
  providers: [{ provide: OpUploadService, useClass: AvatarUploadService }],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AvatarUploadFormComponent implements OnInit {
  public form:any;

  public target:string;

  public method:string;

  public avatarFile:File;

  public avatarPreviewUrl:string;

  public busy = false;

  public fileInvalid = false;

  @ViewChild('avatarFilePicker', { static: true }) public avatarFilePicker:ElementRef<HTMLInputElement>;

  // Text
  public text = {
    label_choose_avatar: this.I18n.t('js.avatars.label_choose_avatar'),
    upload_instructions: this.I18n.t('js.avatars.text_upload_instructions'),
    error_too_large: this.I18n.t('js.avatars.error_image_too_large'),
    wrong_file_format: this.I18n.t('js.avatars.wrong_file_format'),
    button_update: this.I18n.t('js.button_update'),
    uploading: this.I18n.t('js.avatars.uploading_avatar'),
    preview: this.I18n.t('js.label_preview'),
  };

  public constructor(
    protected I18n:I18nService,
    protected elementRef:ElementRef,
    protected cdRef:ChangeDetectorRef,
    protected toastService:ToastService,
    protected uploadService:OpUploadService,
  ) { }

  public ngOnInit() {
    const element = this.elementRef.nativeElement as HTMLElement;
    this.target = element.getAttribute('target') || '';
    this.method = element.getAttribute('method') || '';
  }

  public onFilePickerChanged(_evt:Event) {
    const fileList = this.avatarFilePicker.nativeElement.files;
    if (fileList === null || fileList.length === 0) {
      return;
    }

    const file = fileList[0];
    if (['image/jpeg', 'image/png', 'image/gif'].indexOf(file.type) === -1) {
      this.fileInvalid = true;
      this.cdRef.detectChanges();
      return;
    }

    void resizeFile(128, file).then(([dataURL, blob]) => {
      // Create resized file
      this.avatarFile = new File([blob], file.name);
      this.avatarPreviewUrl = dataURL;
      this.fileInvalid = false;
      this.cdRef.detectChanges();
    });
  }

  public uploadAvatar(event:Event) {
    event.preventDefault();
    this.busy = true;
    const uploadFile:AvatarUploadFile = { file: this.avatarFile, method: this.method };
    const observable = this.uploadService.upload<string>(this.target, [uploadFile])[0];
    this.toastService.addUpload(this.text.uploading, [[this.avatarFile, observable]]);

    observable.subscribe(
      (ev) => {
        switch (ev.type) {
          case 0:
            // Sent
            break;
          case 4:
            this.busy = false;
            window.location.reload();
            break;
          default:
          // Sent or unknown event
        }
      },
      (error:HttpErrorResponse) => {
        this.toastService.addError(error);
        this.busy = false;
      },
    );
  }
}
