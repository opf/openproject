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

import { TurboGlobalEventHandlersEventMap } from '@hotwired/turbo';

type TurboEvent = keyof TurboGlobalEventHandlersEventMap;

// Compile-time guard: TypeScript errors if any TurboEvent key is absent from the array
function allTurboEvents<T extends readonly TurboEvent[]>(
  events:T & ([TurboEvent] extends [T[number]] ? unknown : never),
):readonly TurboEvent[] {
  return events;
}

export function getTurboEvents():readonly TurboEvent[] {
  return allTurboEvents([
    'turbo:before-cache',
    'turbo:before-fetch-request',
    'turbo:before-fetch-response',
    'turbo:before-frame-morph',
    'turbo:before-frame-render',
    'turbo:before-morph-attribute',
    'turbo:before-morph-element',
    'turbo:before-prefetch',
    'turbo:before-render',
    'turbo:before-stream-render',
    'turbo:before-visit',
    'turbo:click',
    'turbo:fetch-request-error',
    'turbo:frame-load',
    'turbo:frame-missing',
    'turbo:frame-render',
    'turbo:load',
    'turbo:morph-element',
    'turbo:morph',
    'turbo:reload',
    'turbo:render',
    'turbo:submit-end',
    'turbo:submit-start',
    'turbo:visit',
  ] as const);
}
