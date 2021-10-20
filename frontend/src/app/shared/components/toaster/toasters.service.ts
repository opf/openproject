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

import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { input, State } from 'reactivestates';
import { Injectable } from '@angular/core';
import { UploadInProgress } from 'core-app/core/file-upload/op-file-upload.service';

export function removeSuccessFlashMessages() {
  jQuery('.flash.notice').remove();
}

export type ToasterType = 'success'|'error'|'warning'|'info'|'upload';
export const OPToasterEvent = 'op:toasters:add';

export interface IToaster {
  message:string;
  link?:{ text:string, target:Function };
  type:ToasterType;
  data?:any;
}

@Injectable({ providedIn: 'root' })
export class ToastersService {
  // The current stack of toasters
  private stack = input<IToaster[]>([]);

  constructor(readonly configurationService:ConfigurationService) {
    jQuery(window)
      .on(OPToasterEvent,
        (event:JQuery.TriggeredEvent, toaster:IToaster) => {
          this.add(toaster);
        });
  }

  /**
   * Get a read-only view of the current stack of toasters.
   */
  public get current():State<IToaster[]> {
    return this.stack;
  }

  public add(toaster:IToaster, timeoutAfter = 5000) {
    // Remove flash messages
    removeSuccessFlashMessages();

    this.stack.doModify((current) => {
      const nextValue = [toaster].concat(current);
      _.remove(nextValue, (n, i) => i > 0 && (n.type === 'success' || n.type === 'error'));
      return nextValue;
    });

    // auto-hide if success
    if (toaster.type === 'success' && this.configurationService.autoHidePopups()) {
      setTimeout(() => this.remove(toaster), timeoutAfter);
    }

    return toaster;
  }

  public addError(message:IToaster|string, errors:any[]|string = []) {
    if (!Array.isArray(errors)) {
      errors = [errors];
    }

    const toaster:IToaster = this.createToaster(message, 'error');
    toaster.data = errors;

    return this.add(toaster);
  }

  public addWarning(message:IToaster|string) {
    return this.add(this.createToaster(message, 'warning'));
  }

  public addSuccess(message:IToaster|string) {
    return this.add(this.createToaster(message, 'success'));
  }

  public addNotice(message:IToaster|string) {
    return this.add(this.createToaster(message, 'info'));
  }

  public addAttachmentUpload(message:IToaster|string, uploads:UploadInProgress[]) {
    return this.add(this.createAttachmentUploadToaster(message, uploads));
  }

  public remove(toaster:IToaster) {
    this.stack.doModify((current) => {
      _.remove(current, (n) => n === toaster);
      return current;
    });
  }

  public clear() {
    this.stack.putValue([]);
  }

  private createToaster(message:IToaster|string, type:ToasterType):IToaster {
    if (typeof message === 'string') {
      return { message, type };
    }
    message.type = type;

    return message;
  }

  private createAttachmentUploadToaster(message:IToaster|string, uploads:UploadInProgress[]) {
    if (!uploads.length) {
      throw new Error('Cannot create an upload toaster without uploads!');
    }

    const toaster = this.createToaster(message, 'upload');
    toaster.data = uploads;

    return toaster;
  }
}
