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

import { Component, ElementRef, EventEmitter, Input, OnInit, Output, ViewChild } from '@angular/core';
import { UploadFile, UploadHttpEvent, UploadInProgress } from "core-components/api/op-file-upload/op-file-upload.service";
import { HttpErrorResponse, HttpEventType, HttpProgressEvent } from "@angular/common/http";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { debugLog } from "core-app/helpers/debug_output";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'notifications-upload-progress',
  template: `
    <li>
      <span class="filename" [textContent]="fileName"></span>
      <progress max="100" value="0" #progressBar></progress>
      <p #progressPercentage>0%</p>
      <span class="upload-completed" *ngIf="completed || error">
      <op-icon icon-classes="icon-close" *ngIf="error"></op-icon>
      <op-icon icon-classes="icon-checkmark" *ngIf="completed"></op-icon>
    </span>
    </li>
  `
})
export class UploadProgressComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public upload:UploadInProgress;
  @Output() public onError = new EventEmitter<HttpErrorResponse>();
  @Output() public onSuccess = new EventEmitter<undefined>();

  @ViewChild('progressBar')
  progressBar:ElementRef;
  @ViewChild('progressPercentage')
  progressPercentage:ElementRef;

  public file:UploadFile;
  public error = false;
  public completed = false;

  set value(value:number) {
    this.progressBar.nativeElement.value = value;
    this.progressPercentage.nativeElement.innerText = `${value}%`;

    if (value === 100) {
      this.progressBar.nativeElement.style.display = 'none';
    }
  }

  constructor(protected readonly I18n:I18nService) {
    super();
  }

  ngOnInit() {
    this.file = this.upload[0];
    const observable = this.upload[1];

    observable
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(
        (evt:UploadHttpEvent) => {
          switch (evt.type) {
          case HttpEventType.Sent:
            this.value = 5;
            return debugLog(`Uploading file "${this.file.name}" of size ${this.file.size}.`);

          case HttpEventType.UploadProgress:
            return this.updateProgress(evt);

          case HttpEventType.Response:
            debugLog(`File ${this.fileName} was fully uploaded.`);
            this.value = 100;
            this.completed = true;
            return this.onSuccess.emit();

          default:
            // Sent or unknown event
            return;
          }
        },
        (error:HttpErrorResponse) => this.handleError(error)
      );
  }

  public get fileName():string|undefined {
    return this.file && this.file.name;
  }

  private updateProgress(evt:HttpProgressEvent) {
    if (evt.total) {
      this.value = Math.round(evt.loaded / evt.total * 100);
    } else {
      this.value = 10;
    }
  }

  private handleError(error:HttpErrorResponse) {
    this.error = true;
    this.onError.emit(error);
  }
}

