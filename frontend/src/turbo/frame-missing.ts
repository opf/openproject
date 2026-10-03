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

import { whenDebugging } from 'core-app/shared/helpers/debug_output';

// Stopgap for links and forms that leave a <turbo-frame> without declaring
// data-turbo-frame="_top". Remove once those callers are explicit:
// https://community.openproject.org/wp/OP-20223
export function addFrameMissingListener(target:Document = document, signal?:AbortSignal) {
  target.addEventListener('turbo:frame-missing', (event) => {
    const { detail: { response, visit } } = event;
    if (!response.ok) {
      return;
    }

    whenDebugging(() => warnAboutImplicitNavigation(event.target, response.url));

    if (withoutFragment(response.url) === withoutFragment(window.location.href)) {
      return;
    }

    event.preventDefault();
    void visit(response, {});
  }, { signal });
}

function withoutFragment(url:string) {
  const parsed = new URL(url, window.location.href);
  parsed.hash = '';
  return parsed.href;
}

function warnAboutImplicitNavigation(frame:EventTarget|null, url:string) {
  const name = frame instanceof Element && frame.id ? `turbo-frame#${frame.id}` : 'a turbo-frame';
  console.warn(`${name} is missing from the response of ${url}. To navigate out of the frame, declare data-turbo-frame="_top".`);
}
