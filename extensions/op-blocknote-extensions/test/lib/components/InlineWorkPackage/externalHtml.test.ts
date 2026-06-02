// @vitest-environment jsdom
import { describe, it, expect } from "vitest";
import {
  computeWorkPackageInlineExternalData,
  buildWorkPackageInlineExternalDOM,
  parseWorkPackageInlineExternalHTML,
} from "../../../../lib/components/InlineWorkPackage/externalHtml";

describe("computeWorkPackageInlineExternalData", () => {
  it("returns null when wpid is absent", () => {
    expect(computeWorkPackageInlineExternalData({})).toBeNull();
  });

  it("returns null when wpid is empty string", () => {
    expect(computeWorkPackageInlineExternalData({ wpid: "" })).toBeNull();
  });

  it("returns null for a pending wpid", () => {
    expect(computeWorkPackageInlineExternalData({ wpid: "pending:abc123" })).toBeNull();
  });

  it("returns correct attrs for a valid wpid", () => {
    const result = computeWorkPackageInlineExternalData({ wpid: "57", instanceId: "inst1", size: "xs" });
    expect(result).toEqual({
      attrs: {
        "data-inline-content-type": "openProjectWorkPackageInline",
        "data-wpid": "57",
        "data-instance-id": "inst1",
        "data-size": "xs",
      },
      text: "#57",
    });
  });

  it("defaults size to \"s\" when absent", () => {
    expect(computeWorkPackageInlineExternalData({ wpid: "1" })?.attrs["data-size"]).toBe("s");
  });

  it("defaults instanceId to empty string when absent", () => {
    expect(computeWorkPackageInlineExternalData({ wpid: "1" })?.attrs["data-instance-id"]).toBe("");
  });
});

describe("buildWorkPackageInlineExternalDOM", () => {
  it("returns a <span> with all four data attributes", () => {
    const data = computeWorkPackageInlineExternalData({ wpid: "57", instanceId: "inst1", size: "xs" })!;
    const el = buildWorkPackageInlineExternalDOM(data, document);
    expect(el.tagName.toLowerCase()).toBe("span");
    expect(el.getAttribute("data-inline-content-type")).toBe("openProjectWorkPackageInline");
    expect(el.getAttribute("data-wpid")).toBe("57");
    expect(el.getAttribute("data-instance-id")).toBe("inst1");
    expect(el.getAttribute("data-size")).toBe("xs");
  });

  it("sets text content to '#<wpid>'", () => {
    const data = computeWorkPackageInlineExternalData({ wpid: "57" })!;
    expect(buildWorkPackageInlineExternalDOM(data, document).textContent).toBe("#57");
  });
});

describe("parseWorkPackageInlineExternalHTML", () => {
  it("returns undefined for a plain <span>", () => {
    expect(parseWorkPackageInlineExternalHTML(document.createElement("span"))).toBeUndefined();
  });

  it("returns undefined when data-inline-content-type does not match", () => {
    const el = document.createElement("span");
    el.setAttribute("data-inline-content-type", "somethingElse");
    expect(parseWorkPackageInlineExternalHTML(el)).toBeUndefined();
  });

  it("returns correct props from a valid element", () => {
    const el = document.createElement("span");
    el.setAttribute("data-inline-content-type", "openProjectWorkPackageInline");
    el.setAttribute("data-wpid", "57");
    el.setAttribute("data-instance-id", "inst1");
    el.setAttribute("data-size", "xs");
    expect(parseWorkPackageInlineExternalHTML(el)).toEqual({ wpid: "57", instanceId: "inst1", size: "xs" });
  });

  it("falls back to size \"s\" when data-size is absent", () => {
    const el = document.createElement("span");
    el.setAttribute("data-inline-content-type", "openProjectWorkPackageInline");
    el.setAttribute("data-wpid", "57");
    expect(parseWorkPackageInlineExternalHTML(el)?.size).toBe("s");
  });
});

describe("round-trip: compute → build → parse", () => {
  it("recovers wpid, instanceId, and size", () => {
    const data = computeWorkPackageInlineExternalData({ wpid: "57", instanceId: "inst1", size: "xs" })!;
    const el = buildWorkPackageInlineExternalDOM(data, document);
    expect(parseWorkPackageInlineExternalHTML(el)).toEqual({ wpid: "57", instanceId: "inst1", size: "xs" });
  });
});
