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

import type { CloseEvent } from "@hocuspocus/common";

/**
 * WebSocket close codes 4000-4999 are reserved for application use.
 * We mirror HTTP status codes where applicable.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/API/WebSocket/close
 * @see https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent/code
 */

/**
 * Token has expired. Client should refresh and reconnect.
 * Code 4401 mirrors HTTP 401 Unauthorized.
 */
export const TokenExpired: CloseEvent = {
  code: 4401,
  reason: "Token expired",
};

/**
 * Token expiry timestamp missing from connection context.
 * Indicates a server configuration or authentication flow issue.
 * Code 4500 mirrors HTTP 500 Internal Server Error.
 */
export const TokenExpiryMissing: CloseEvent = {
  code: 4500,
  reason: "Token expiry not set",
};

/**
 * Factory for creating Unauthorized close events with custom reasons.
 * Use for token sync failures, validation errors, etc.
 */
export function unauthorized(reason: string): CloseEvent {
  return { code: 4401, reason };
}
