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

import { decryptToken } from "./decryptTokenService";
import { fetchResource } from "./resourceService";
import type { ApiResponseDocument } from "../types";

export interface TokenValidationResult {
  decryptedToken: string;
  readonly: boolean;
  tokenExpiresAt: string;
}

/**
 * Decrypt and validate packed auth params against the OpenProject API.
 * Validates origin and resource URL match, then verifies access with the API.
 * Returns the decrypted oauth_token and readonly status, or throws if validation fails.
 */
export async function decryptAndValidateToken(
  encryptedToken: string,
  resourceUrl: string,
  requestOrigin?: string
): Promise<TokenValidationResult> {
  const {
    resource_url: tokenResourceUrl,
    oauth_token,
    expires_at,
  } = decryptToken(encryptedToken);

  if (requestOrigin && !tokenResourceUrl?.startsWith(requestOrigin)) {
    throw new Error(`Unauthorized: Token origin does not match request origin. Expected ${tokenResourceUrl} to start with ${requestOrigin}.`);
  }

  if (tokenResourceUrl !== resourceUrl) {
    throw new Error(`Unauthorized: Token resource URL does not match document. Expected ${tokenResourceUrl}, got ${resourceUrl}.`);
  }

  const response = await fetchResource(resourceUrl, oauth_token);

  if (!response.ok) {
    const detail = response.statusText ? `: ${response.statusText}` : ".";
    throw new Error(`Unauthorized: Invalid token or document access denied${detail}`);
  }

  const jsonData = await response.json() as ApiResponseDocument;
  return {
    decryptedToken: oauth_token,
    readonly: !jsonData._links?.update,
    tokenExpiresAt: expires_at,
  };
}
