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
