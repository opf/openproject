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

import { debugLog } from 'core-app/shared/helpers/debug_output';
import {
  ErrorReporterBase,
  MessageSeverity,
  toError,
} from 'core-app/core/errors/error-reporter-base';

export class LocalReporter extends ErrorReporterBase {
  public captureMessage(msg:string, severity:MessageSeverity = 'info'):void {
    this.handleOfflineMessage('captureMessage', [msg, severity]);
  }

  public captureException(err:unknown):void {
    this.handleOfflineMessage('captureException', [err]);

    // Angular's global error listeners call preventDefault() only after the
    // ErrorHandler returns. Throwing here keeps the error uncaught, so it
    // still reaches the browser console and the browser error check of
    // feature specs.
    throw toError(err);
  }

  /**
   * Remember a message or error for later handling
   * @param type
   * @param args
   */
  private handleOfflineMessage(type:'captureMessage'|'captureException', args:unknown[]) {
    debugLog('[ErrorReporter] Would queue message %O %O, but is not configured.', type, args);
  }
}
