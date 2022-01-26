// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  IToast,
  ToastService,
  ToastType,
} from './toast.service';

@Component({
  templateUrl: './toast.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'op-toast',
})
export class ToastComponent implements OnInit {
  @Input() public toast:IToast;

  public text = {
    close_popup: this.I18n.t('js.close_popup_title'),
  };

  public type:ToastType;

  public uploadCount = 0;

  public show = false;

  constructor(readonly I18n:I18nService,
    readonly toastService:ToastService) {
  }

  ngOnInit() {
    this.type = this.toast.type;
  }

  public get data() {
    return this.toast.data;
  }

  public canBeHidden() {
    return this.data && this.data.length > 5;
  }

  public removable() {
    return this.toast.type !== 'upload';
  }

  public remove() {
    this.toastService.remove(this.toast);
  }

  /**
   * Execute the link callback from content.link.target
   * and close this toaster.
   */
  public executeTarget() {
    if (this.toast.link) {
      this.toast.link.target();
      this.remove();
    }
  }

  public onUploadError(message:string) {
    this.remove();
  }

  public onUploadSuccess() {
    this.uploadCount += 1;
  }

  public get uploadText() {
    return this.I18n.t('js.label_upload_counter',
      { done: this.uploadCount, count: this.data.length });
  }
}
