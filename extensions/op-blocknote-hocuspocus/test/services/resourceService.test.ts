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

import { http, HttpResponse } from "msw";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import { server } from "../mocks/node";

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

  describe("logging", () => {
    test("logs method, URL and status, but never the token", async () => {
      const log = vi.spyOn(console, "log").mockImplementation(() => {});
      const { fetchResource } = await import("../../src/services/resourceService");

      await fetchResource("https://test.openproject.com/api/v3/documents/42", "__valid_oauth_token");

      const output = log.mock.calls.flat().join("\n");
      expect(output).toMatch(/\] GET https:\/\/test\.openproject\.com\/api\/v3\/documents\/42 request_id=\S+ -> 200 \(\d+ms\)/);
      expect(output).not.toContain("__valid_oauth_token");
      log.mockRestore();
    });
  });
});

describe("describeErrorResponse", () => {
  const resourceUrl = "https://test.openproject.com/api/v3/documents/42";

  async function errorResponse(body: string) {
    server.use(http.get(resourceUrl, () => new HttpResponse(body, { status: 500 })));
    return fetch(resourceUrl);
  }

  test("logs error bodies on a single line", async () => {
    const { describeErrorResponse } = await import("../../src/services/resourceService");
    const response = await errorResponse(JSON.stringify({
      _type: "Error",
      errorIdentifier: "urn:openproject-org:api:v3:errors:MissingPermission",
      message: "You are not authorized to access this resource.",
    }, null, 2));

    const description = await describeErrorResponse(response);

    expect(description).toEqual('{ "_type": "Error", "errorIdentifier": "urn:openproject-org:api:v3:errors:MissingPermission", "message": "You are not authorized to access this resource." }');
    expect(await response.json()).toMatchObject({ _type: "Error" });
  });
});

describe("describeFetchError", () => {
  test("includes the underlying cause of a failed fetch", async () => {
    const { describeFetchError } = await import("../../src/services/resourceService");
    const cause = Object.assign(new Error("connect ECONNREFUSED 127.0.0.1:3000"), {
      code: "ECONNREFUSED",
      syscall: "connect",
      address: "127.0.0.1",
      port: 3000,
    });

    expect(describeFetchError(new TypeError("fetch failed", { cause })))
      .toEqual("fetch failed (connect ECONNREFUSED 127.0.0.1:3000)");
  });
});
