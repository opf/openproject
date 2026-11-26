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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ErrorHandler, Injectable } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { HalError } from 'core-app/features/hal/services/hal-error';

function isServerOrNetworkFailure(response:HttpErrorResponse):boolean {
  return response.status === 0 || response.status >= 500;
}

const reported = new WeakSet<object>();

export function wasReported(error:unknown):boolean {
  return typeof error === 'object' && error !== null && reported.has(error);
}

@Injectable()
export class HalAwareErrorHandler extends ErrorHandler {
  public handleError(error:unknown):void {
    super.handleError(error);

    if (typeof error === 'object' && error !== null) {
      reported.add(error);
    }

    if (error instanceof HalError) {
      if (isServerOrNetworkFailure(error.httpError)) {
        window.ErrorReporter.captureException(error);
      }
    } else if (error instanceof HttpErrorResponse) {
      if (isServerOrNetworkFailure(error)) {
        window.ErrorReporter.captureException(error);
      }
    } else {
      window.ErrorReporter.captureException(error);
    }
  }
}
