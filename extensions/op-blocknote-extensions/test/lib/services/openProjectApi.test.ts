import {describe, it, expect, vi} from "vitest";
import {initOpenProjectApi, linkToWorkPackage, searchWorkPackages} from "../../../lib/services/openProjectApi";

describe("openProjectApi", () => {
  it("works with a baseUrl with trailing slash", () => {
    initOpenProjectApi({baseUrl: "https://example.com/"});
    expect(linkToWorkPackage('42')).toBe("https://example.com/wp/42");
  });

  it("works with a baseUrl without trailing slash", () => {
    initOpenProjectApi({baseUrl: "https://example.com"});
    expect(linkToWorkPackage('42')).toBe("https://example.com/wp/42");
  });

  describe("searchWorkPackages", () => {
    it("should fetch work packages sorted by updatedAt descending", () => {
      initOpenProjectApi({baseUrl: "http://localhost:3000"});
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        json: async () => ({ _embedded: { elements: [] } }),
      } as Response);

      searchWorkPackages("test query");

      const calledUrl = fetchSpy.mock.calls[0][0] as string;
      expect(calledUrl).toContain("sortBy=%5B%5B%22updatedAt%22%2C%22desc%22%5D%5D");

      fetchSpy.mockRestore();
    })
  });
});