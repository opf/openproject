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

import { HttpErrorResponse } from '@angular/common/http';

export type MessageSeverity = 'fatal'|'error'|'warning'|'log'|'info'|'debug';
export type ErrorTags = Record<string, string>;
export type ContextHook = () => ErrorTags|Promise<ErrorTags>;

export abstract class ErrorReporterBase {
  protected contextHooks:ContextHook[] = [];

  public addHook(...hook:ContextHook[]):void {
    this.contextHooks.push(...hook);
  }

  // A failing hook must not keep the error from being reported, nor become an
  // unhandled rejection that is reported in turn.
  protected async contextTags():Promise<ErrorTags> {
    const results = await Promise.allSettled(this.contextHooks.map((hook) => Promise.resolve().then(hook)));

    return results.reduce<ErrorTags>(
      (tags, result) => (result.status === 'fulfilled' ? { ...tags, ...result.value } : tags),
      {},
    );
  }

  /** Capture a message */
  abstract captureMessage(msg:string, level?:MessageSeverity):void;

  abstract captureException(err:unknown):void;
}

export function toError(value:unknown):Error {
  if (value instanceof Error) {
    return value;
  }

  if (value instanceof HttpErrorResponse) {
    return new Error(value.message, { cause: value });
  }

  if (typeof value === 'string') {
    return new Error(value);
  }

  return new Error(`Non-error value captured: ${String(value)}`, { cause: value });
}
