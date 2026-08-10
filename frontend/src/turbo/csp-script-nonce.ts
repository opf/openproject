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

import { getMetaContent } from 'core-app/core/setup/globals/global-helpers';

export function readScriptNonce():string {
  return getMetaContent('csp-nonce');
}

// Turbo re-adds nonces to all scripts, even though we want to explicitly
// control which ones run: https://github.com/hotwired/turbo/issues/294#issuecomment-2633216052
// Removes every <script> in a freshly-rendered fragment whose nonce does not
// match ours, so an unauthenticated or stale inline script never executes.
// The nonce is read per call because Turbo merges <head> across visits, so the
// meta can change; a stale boot-time read would scrub the wrong scripts.
export function scrubScriptElements(
  fragment:HTMLElement | DocumentFragment,
  nonce:string = readScriptNonce(),
):void {
  fragment
    .querySelectorAll('script')
    .forEach((script) => {
      const scriptNonce = script.getAttribute('nonce');

      if (!(scriptNonce && scriptNonce === nonce)) {
        console.warn('Removing script element %O because it does not match our nonce', script);
        script.remove();
      }
    });
}
