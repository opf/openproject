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
    vi.restoreAllMocks();
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
    const output = (spy: { mock: { calls: unknown[][] } }) => spy.mock.calls.map((call) => call.join(" ")).join("\n");

    test("logs method, URL and status, but never the token", async () => {
      const log = vi.spyOn(console, "log").mockImplementation(() => {});
      const { fetchResource } = await import("../../src/services/resourceService");

      await fetchResource("https://test.openproject.com/api/v3/documents/42", "__valid_oauth_token");

      expect(output(log)).toMatch(/^OP \[\S+\] GET https:\/\/test\.openproject\.com\/api\/v3\/documents\/42 -> 200 \(\d+ms\)/m);
      expect(output(log)).not.toContain("__valid_oauth_token");
    });

    test("logs the response body of a failed request", async () => {
      const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
      const resourceUrl = "https://test.openproject.com/api/v3/documents/42";
      const body = JSON.stringify({ _type: "Error", message: "You are not authorized to access this resource." });
      server.use(http.get(resourceUrl, () => new HttpResponse(body, { status: 403 })));
      const { fetchResource } = await import("../../src/services/resourceService");

      const response = await fetchResource(resourceUrl, "__valid_oauth_token");

      expect(output(warn)).toMatch(/-> 403 \(\d+ms\) .*not authorized/);
      expect(await response.json()).toMatchObject({ _type: "Error" });
    });

    test("truncates a long response body", async () => {
      const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
      const resourceUrl = "https://test.openproject.com/api/v3/documents/42";
      server.use(http.get(resourceUrl, () => new HttpResponse("x".repeat(5000), { status: 502 })));
      const { fetchResource } = await import("../../src/services/resourceService");

      await fetchResource(resourceUrl, "__valid_oauth_token");

      expect(output(warn)).toContain("x".repeat(2000));
      expect(output(warn)).not.toContain("x".repeat(2001));
    });

    test("logs and rethrows the error of a request that cannot be sent", async () => {
      const error = vi.spyOn(console, "error").mockImplementation(() => {});
      const resourceUrl = "https://test.openproject.com/api/v3/documents/42";
      server.use(http.get(resourceUrl, () => HttpResponse.error()));
      const { fetchResource } = await import("../../src/services/resourceService");

      const failure = await fetchResource(resourceUrl, "__valid_oauth_token").catch((e: unknown) => e);

      expect(failure).toBeInstanceOf(TypeError);
      expect(output(error)).toMatch(/failed after \d+ms/);
      expect(error.mock.calls.some((call) => call.includes(failure))).toBe(true);
    });
  });
});
