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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ErrorHandler, Injectable, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { HalError } from 'core-app/features/hal/services/hal-error';
import { HttpErrorResponse } from '@angular/common/http';

interface RejectedPromise {
  rejection:unknown;
}

@Injectable()
export class HalAwareErrorHandler extends ErrorHandler {
  private readonly I18n = inject(I18nService);

  private text = {
    internal_error: this.I18n.t('js.error.internal'),
  };

  public handleError(error:unknown):void {
    let message:string = this.text.internal_error;

    // Angular wraps our errors into uncaught promises if
    // no one catches the error explicitly. Unwrap the error in that case
    if ((error as RejectedPromise)?.rejection instanceof HalError) {
      this.handleError((error as RejectedPromise).rejection);
      return;
    }

    if (error instanceof HalError) {
      console.error('Returned HTTP HAL error resource %O', error.message);
      message = error.httpError?.status >= 500 ? `${message} ${error.message}` : error.message;
      HalAwareErrorHandler.captureError(error.httpError);
    } else if (error instanceof ErrorResource) {
      console.error('Returned error resource %O', error);
      message += ` ${error.errorMessages.join('\n')}`;
    } else if (error instanceof HalResource) {
      console.error('Returned hal resource %O', error);
      message += `Resource returned ${error.name}`;
    } else if (error instanceof Error) {
      window.ErrorReporter.captureException(error);
    } else if (error instanceof HttpErrorResponse) {
      HalAwareErrorHandler.captureError(error);
      message = error.message;
    } else if (typeof error === 'string') {
      window.ErrorReporter.captureMessage(error);
      message = error;
    }

    super.handleError(message);
  }

  /**
   * Report any errors to APM tool, if configured.
   *
   * The Application Performance Monitoring tool will filter according to their
   * error status.
   *
   * @param error
   * @private
   */
  private static captureError(error:Error|HttpErrorResponse):void {
    window.ErrorReporter.captureException(error);
  }
}
