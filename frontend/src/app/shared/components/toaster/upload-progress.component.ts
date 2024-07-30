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
import {
  HttpErrorResponse,
  HttpEvent,
  HttpEventType,
  HttpProgressEvent,
} from '@angular/common/http';
import { BehaviorSubject, combineLatest, Observable } from 'rxjs';

import { debugLog } from 'core-app/shared/helpers/debug_output';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';

@Component({
  selector: 'op-toasters-upload-progress',
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
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class UploadProgressComponent extends UntilDestroyedMixin implements OnInit, AfterViewInit {
  @Input() public file:File;

  @Input() public upload:Observable<HttpEvent<unknown>>;

  @Output() public uploadError = new EventEmitter<HttpErrorResponse>();

  @Output() public uploadSuccess = new EventEmitter<void>();

  @ViewChild('progressBar') progressBar:ElementRef;

  @ViewChild('progressPercentage') progressPercentage:ElementRef;

  public error = false;

  public completed = false;

  private viewInitialized = new BehaviorSubject<boolean>(false);

  set value(value:number) {
    (this.progressBar.nativeElement as HTMLProgressElement).value = value;
    (this.progressPercentage.nativeElement as HTMLParagraphElement).innerText = `${value}%`;

    if (value === 100) {
      (this.progressBar.nativeElement as HTMLElement).style.display = 'none';
    }
  }

  ngOnInit() {
    combineLatest([
      this.upload,
      this.viewInitialized,
    ]).pipe(this.untilDestroyed())
      .subscribe(
        ([evt, initialized]) => {
          if (!initialized) {
            return;
          }

          switch (evt.type) {
            case HttpEventType.Sent:
              this.value = 5;
              debugLog(`Uploading file "${this.file.name}" of size ${this.file.size}.`);
              break;
            case HttpEventType.UploadProgress:
              this.updateProgress(evt);
              break;
            case HttpEventType.Response:
              debugLog(`File ${this.fileName} was fully uploaded.`);
              this.value = 100;
              this.completed = true;
              this.uploadSuccess.emit();
              break;
            case HttpEventType.DownloadProgress:
            case HttpEventType.ResponseHeader:
              /* do nothing */
              break;
            default:
              console.warn(`unknown event type: ${evt.type}`);
          }
        },
        (error:HttpErrorResponse) => this.handleError(error),
      );
  }

  ngAfterViewInit():void {
    this.viewInitialized.next(true);
  }

  public get fileName():string {
    return this.file && this.file.name;
  }

  private updateProgress(evt:HttpProgressEvent) {
    if (evt.total) {
      this.value = Math.round((evt.loaded / evt.total) * 100);
    } else {
      this.value = 10;
    }
  }

  private handleError(error:HttpErrorResponse) {
    this.error = true;
    this.uploadError.emit(error);
  }
}
