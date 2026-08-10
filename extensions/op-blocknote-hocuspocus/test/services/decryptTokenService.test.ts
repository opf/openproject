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

import { describe, expect, test } from "vitest";
import { decryptToken } from "../../src/services/decryptTokenService";
import { createTestToken } from "../helpers/tokenHelper";

describe("decryptToken", () => {
  test("should decrypt a valid encrypted token with expires_at", () => {
    const encrypted = createTestToken({ expires_at: "2030-01-01T00:00:00.000Z" });
    const decrypted = decryptToken(encrypted);

    expect(decrypted.resource_url).toBe("https://test.api/api/v3/documents/1");
    expect(decrypted.oauth_token).toBe("some_token_value");
    expect(decrypted.readonly).toBe(false);
    expect(decrypted.expires_at).toBe("2030-01-01T00:00:00.000Z");
  });
});
