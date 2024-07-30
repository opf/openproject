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

import { Observable } from 'rxjs';
import { take } from 'rxjs/operators';
import { input, State } from '@openproject/reactivestates';
import { Injectable } from '@angular/core';
import { HttpErrorResponse, HttpEvent } from '@angular/common/http';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import waitForUploadsFinished from 'core-app/core/upload/wait-for-uploads-finished';
import { IHalErrorBase, IHalMultipleError, isHalError } from 'core-app/features/hal/resources/error-resource';

export function removeSuccessFlashMessages():void {
  jQuery('.op-toast.-success').remove();
}

export type ToastType = 'success'|'error'|'warning'|'info'|'upload'|'loading';
export const OPToastEvent = 'op:toasters:add';

export interface IToast {
  message:string;
  icon?:string;
  link?:{ text:string, target:() => void };
  type:ToastType;
  data?:unknown;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
  // The current stack of toasters
  private stack = input<IToast[]>([]);

  constructor(
    readonly configurationService:ConfigurationService,
    readonly I18n:I18nService,
  ) {
    jQuery(window).on(
      OPToastEvent,
      (event:JQuery.TriggeredEvent, toast:IToast) => { this.add(toast); },
    );
  }

  /**
   * Get a read-only view of the current stack of toasters.
   */
  public get current():State<IToast[]> {
    return this.stack;
  }

  public add(toast:IToast, timeoutAfter = 5000):IToast {
    // Remove flash messages
    removeSuccessFlashMessages();

    this.stack.doModify((current) => {
      const nextValue = [toast].concat(current);
      _.remove(nextValue, (n, i) => i > 0 && this.removeOnAdd(n));
      return nextValue;
    });

    // auto-hide if success
    if (toast.type === 'success' && this.configurationService.autoHidePopups()) {
      setTimeout(() => this.remove(toast), timeoutAfter);
    }

    return toast;
  }

  private removeOnAdd(toast:IToast):boolean {
    return ['success', 'error', 'loading'].includes(toast.type);
  }

  public addError(obj:HttpErrorResponse|IToast|string, additionalErrors:unknown[]|string = []):IToast|null {
    let message:IToast|string;
    let errors:string[];

    if (typeof additionalErrors === 'string') {
      errors = [additionalErrors];
    } else {
      errors = [...additionalErrors] as string[];
    }

    if (obj instanceof HttpErrorResponse) {
      if (obj.status === 0) {
        console.error('Request cancelled or failed otherwise: %O', obj);
        return null;
      }

      message = isHalError(obj.error) ? obj.error.message : obj.message;

      if ((obj.error as IHalMultipleError)?._embedded?.errors) {
        errors = [
          ...errors,
          ...(obj.error as IHalMultipleError)._embedded.errors.map((el:IHalErrorBase) => el.message),
        ];
      }
    } else {
      message = obj;
    }

    const toast:IToast = this.createToast(message, 'error');
    toast.data = errors;

    return this.add(toast);
  }

  public addWarning(message:IToast|string):IToast {
    return this.add(this.createToast(message, 'warning'));
  }

  public addSuccess(message:IToast|string):IToast {
    return this.add(this.createToast(message, 'success'));
  }

  public addNotice(message:IToast|string):IToast {
    return this.add(this.createToast(message, 'info'));
  }

  public addUpload(message:string, uploads:[File, Observable<HttpEvent<unknown>>][]):IToast {
    if (!uploads.length) {
      throw new Error('Cannot create an upload toast without uploads!');
    }

    const notification = this.add({
      data: uploads,
      type: 'upload',
      message,
    });

    waitForUploadsFinished(uploads.map((o) => o[1]))
      .pipe(take(1))
      .subscribe(() => {
        setTimeout(() => this.remove(notification), 700);
      });

    return notification;
  }

  public addLoading(observable:Observable<unknown>):IToast {
    return this.add(this.createLoadingToast(this.I18n.t('js.ajax.updating'), observable));
  }

  public remove(toast:IToast):void {
    this.stack.doModify((current) => {
      _.remove(current, (n) => n === toast);
      return current;
    });
  }

  public clear():void {
    this.stack.putValue([]);
  }

  private createToast(toast:IToast|string, type:ToastType):IToast {
    return (typeof toast === 'string')
      ? { message: toast, type }
      : {
        message: toast.message,
        type,
        link: toast.link,
        icon: toast.icon,
        data: toast.data,
      };
  }

  private createLoadingToast(message:IToast|string, observable:Observable<unknown>) {
    const toast = this.createToast(message, 'loading');
    toast.data = observable;

    return toast;
  }
}
