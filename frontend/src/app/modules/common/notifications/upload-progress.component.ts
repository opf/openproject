//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
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

import {Component, EventEmitter, Input, OnInit, Output} from '@angular/core';

@Component({
  selector: 'notifications-upload-progress',
  template: `
  <li>
    <span class="filename" [textContent]="file"></span>
    <progress [hidden]="completed" max="100" [value]="value">{{value}}%</progress>
    <span class="upload-completed" *ngIf="completed || error">
      <op-icon icon-classes="icon-close" *ngIf="error"></op-icon>
      <op-icon icon-classes="icon-checkmark" *ngIf="completed"></op-icon>
    </span>
  </li>
  `
})
export class UploadProgressComponent implements OnInit {
  @Input() public upload:any;
  @Output() public onError = new EventEmitter<any>();
  @Output() public onSuccess = new EventEmitter<any>();

  public file:string = '';
  public value:number = 0;
  public completed = false;

  ngOnInit() {
    this.upload.progress((details:any) => {
      var file = details.config.file || details.config.data.file;
      this.file = _.get(file, 'name', '');
      if (details.lengthComputable) {
        this.value = Math.round(details.loaded / details.total * 100);
      } else {
        // dummy value if not computable
        this.value = 10;
      }
    }).success(() => {
      this.value = 100;
      this.completed = true;
      this.onSuccess.emit();
    }).error(() => {
      this.onError.emit();
    });
  }
}

