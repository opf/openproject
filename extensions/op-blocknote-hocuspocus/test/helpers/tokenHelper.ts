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

import { createCipheriv, createHash, randomBytes } from "node:crypto";
import { ALGORITHM, SECRET_ENV } from "../../src/services/decryptTokenService";

const SECRET = createHash("sha256").update(SECRET_ENV).digest();

interface TokenParams {
  resource_url: string;
  oauth_token: string;
  expires_at: string;
  readonly: boolean;
}

export function encryptToken(params: TokenParams): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGORITHM, SECRET, iv);

  const encrypted = Buffer.concat([
    cipher.update(JSON.stringify(params)),
    cipher.final()
  ]);

  const authTag = cipher.getAuthTag();

  return [
    encrypted.toString("base64"),
    iv.toString("base64"),
    authTag.toString("base64")
  ].join("--");
}

export function createTestToken(overrides: Partial<TokenParams> = {}): string {
  const futureDate = new Date(Date.now() + 5 * 60 * 1000); // 5 min from now

  return encryptToken({
    resource_url: "https://test.api/api/v3/documents/1",
    oauth_token: "some_token_value",
    expires_at: futureDate.toISOString(),
    readonly: false,
    ...overrides
  });
}

export function createExpiredToken(overrides: Partial<TokenParams> = {}): string {
  const pastDate = new Date(Date.now() - 60 * 1000); // 1 min ago

  return encryptToken({
    resource_url: "https://test.api/api/v3/documents/1",
    oauth_token: "some_token_value",
    expires_at: pastDate.toISOString(),
    readonly: false,
    ...overrides
  });
}
