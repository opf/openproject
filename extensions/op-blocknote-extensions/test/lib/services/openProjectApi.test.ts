import { describe, expect, it, vi } from "vitest";
import {
  fetchWorkPackage,
  initOpenProjectApi,
  linkToWorkPackage,
  searchWorkPackages
} from "../../../lib/services/openProjectApi";

describe("openProjectApi", () => {
  it("works with a baseUrl with trailing slash", () => {
    initOpenProjectApi({baseUrl: "https://example.com/"});
    expect(linkToWorkPackage(42)).toBe("https://example.com/wp/42");
  });

  it("works with a baseUrl without trailing slash", () => {
    initOpenProjectApi({baseUrl: "https://example.com"});
    expect(linkToWorkPackage(42)).toBe("https://example.com/wp/42");
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

  describe("linkToWorkPackage", () => {
    it("throws an error for invalid work package ID", () => {
      initOpenProjectApi({baseUrl: "https://example.com"});
      expect(() => linkToWorkPackage(-1)).toThrow("Invalid work package ID: -1");
      expect(() => linkToWorkPackage(0)).toThrow("Invalid work package ID: 0");
      expect(() => linkToWorkPackage(NaN)).toThrow("Invalid work package ID: NaN");
      expect(() => linkToWorkPackage("abublé" as unknown as number)).toThrow("Invalid work package ID: abublé");
    });

    it("builds a welformed url for valid work package ID", () => {
      initOpenProjectApi({baseUrl: "https://example.com"});
      expect(linkToWorkPackage(123)).toBe("https://example.com/wp/123");
    });
  });

  describe("fetchWorkPackage", () => {
    it("rejects for invalid work package ID", async () => {
      initOpenProjectApi({baseUrl: "https://example.com"});
      await expect(fetchWorkPackage(-1)).rejects.toHaveProperty("message", "Invalid work package ID: -1");
      await expect(fetchWorkPackage(0)).rejects.toHaveProperty("message", "Invalid work package ID: 0");
      await expect(fetchWorkPackage(NaN)).rejects.toHaveProperty("message", "Invalid work package ID: NaN");
      await expect(fetchWorkPackage("abublé" as unknown as number)).rejects.toHaveProperty("message", "Invalid work package ID: abublé");
    });
  });
});
