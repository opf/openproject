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

import { environment } from '../../../environments/environment';

/**
 * Execute the callback unless running in a production build.
 */
export function whenDebugging(cb:() => void) {
  if (!environment.production) {
    cb();
  }
}

/**
 * Log with console.log unless running in a production build.
 */
export function debugLog(message:string, ...args:unknown[]):void {
  // eslint-disable-next-line no-console
  whenDebugging(() => console.log(`[DEBUG] ${message}`, ...args));
}

export function timeOutput(msg:string, cb:() => void):any {
  if (!environment.production) {
    const t0 = performance.now();

    const results = cb();

    const t1 = performance.now();
    // eslint-disable-next-line no-console
    console.log(`%c${msg} completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');

    return results;
  }
  return cb();
}

export function asyncTimeOutput(msg:string, promise:Promise<any>):any {
  if (!environment.production) {
    const t0 = performance.now();

    return promise.then(() => {
      const t1 = performance.now();
      // eslint-disable-next-line no-console
      console.log(`%c${msg} completed in ${(t1 - t0)} milliseconds.`, 'color:#00A093;');
    });
  }
  return promise;
}
