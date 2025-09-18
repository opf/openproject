import {describe, it, expect} from "vitest";
import {initOpenProjectApi, linkToWorkPackage} from "../../../lib/services/openProjectApi";

describe("openProjectApi", () => {
  it("works with a baseUrl with trailing slash", () => {
    initOpenProjectApi({baseUrl: "https://example.com/"});
    expect(linkToWorkPackage('42')).toBe("https://example.com/wp/42");
  });

  it("works with a baseUrl without trailing slash", () => {
    initOpenProjectApi({baseUrl: "https://example.com"});
    expect(linkToWorkPackage('42')).toBe("https://example.com/wp/42");
  });
});