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

import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";

// Web requests are mocked via the dynamic document response (see `handlers.ts`) returning
// the `__echo` field we use to confirm the called URL and host header.
describe("fetchResource", () => {
  beforeEach(async () => {
    vi.resetModules();
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  describe("with default configuration (no env vars set)", () => {
    test("requests the resource at the original URL, without a forwarded protocol header", async () => {
      const { fetchResource } = await import("../../src/services/resourceService");

      const resourceUrl = "https://test.openproject.com/api/v3/documents/42";
      const response = await fetchResource(resourceUrl, "__valid_oauth_token").then(r => r.json());

      expect(response).toMatchObject({ __echo: { url: resourceUrl, xForwardedProtoHeader: null }})
    });
  });

  describe("with OPENPROJECT_URL", () => {
    test("Overrides the base URL protocol and host, and sends X-Forwarded-Protocol", async () => {
      vi.stubEnv("OPENPROJECT_URL", "http://web");

      const { fetchResource } = await import("../../src/services/resourceService");

      const resourceUrl = "https://test.openproject.com/api/v3/documents/42";
      const response = await fetchResource(resourceUrl, "__valid_oauth_token").then(r => r.json());

      expect(response).toMatchObject({ __echo: { url: 'http://web/api/v3/documents/42', xForwardedProtoHeader: null }});
    });
  });

  describe("with OPENPROJECT_URL and OPENPROJECT_HTTPS", () => {
    test("Overrides the base URL protocol and host, and sends X-Forwarded-Protocol", async () => {
      vi.stubEnv("OPENPROJECT_URL", "http://web");
      vi.stubEnv("OPENPROJECT_HTTPS", "true");

      const { fetchResource } = await import("../../src/services/resourceService");

      const resourceUrl = "https://test.openproject.com/api/v3/documents/42";
      const response = await fetchResource(resourceUrl, "__valid_oauth_token").then(r => r.json());

      expect(response).toMatchObject({ __echo: { url: 'http://web/api/v3/documents/42', xForwardedProtoHeader: "https" }});
    });
  });
});
