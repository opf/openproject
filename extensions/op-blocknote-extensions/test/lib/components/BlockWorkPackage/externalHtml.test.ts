// @vitest-environment jsdom
import { describe, it, expect } from "vitest";
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
  parseWorkPackageBlockExternalHTML,
} from "../../../../lib/components/BlockWorkPackage/externalHtml";

describe("computeWorkPackageBlockExternalData", () => {
  it("returns null when wpid is absent", () => {
    expect(computeWorkPackageBlockExternalData({})).toBeNull();
  });

  it("returns null when wpid is 0 (falsy)", () => {
    expect(computeWorkPackageBlockExternalData({ wpid: 0 })).toBeNull();
  });

  it("returns correct attrs for a numeric wpid", () => {
    const result = computeWorkPackageBlockExternalData({ wpid: 42, instanceId: "inst1", size: "l" });
    expect(result).toEqual({
      attrs: {
        "data-block-content-type": "openProjectWorkPackageBlock",
        "data-wpid": "42",
        "data-instance-id": "inst1",
        "data-size": "l",
      },
      text: "#42",
    });
  });

  it("returns correct attrs for a string wpid", () => {
    const result = computeWorkPackageBlockExternalData({ wpid: "99" });
    expect(result?.attrs["data-wpid"]).toBe("99");
    expect(result?.text).toBe("#99");
  });

  it("defaults size to \"m\" when absent", () => {
    expect(computeWorkPackageBlockExternalData({ wpid: 1 })?.attrs["data-size"]).toBe("m");
  });

  it("defaults instanceId to empty string when absent", () => {
    expect(computeWorkPackageBlockExternalData({ wpid: 1 })?.attrs["data-instance-id"]).toBe("");
  });
});

describe("buildWorkPackageBlockExternalDOM", () => {
  it("returns a <div> with all four data attributes", () => {
    const data = computeWorkPackageBlockExternalData({ wpid: 42, instanceId: "inst1", size: "l" })!;
    const el = buildWorkPackageBlockExternalDOM(data, document);
    expect(el.tagName.toLowerCase()).toBe("div");
    expect(el.getAttribute("data-block-content-type")).toBe("openProjectWorkPackageBlock");
    expect(el.getAttribute("data-wpid")).toBe("42");
    expect(el.getAttribute("data-instance-id")).toBe("inst1");
    expect(el.getAttribute("data-size")).toBe("l");
  });

  it("sets text content to '#<wpid>'", () => {
    const data = computeWorkPackageBlockExternalData({ wpid: 42 })!;
    expect(buildWorkPackageBlockExternalDOM(data, document).textContent).toBe("#42");
  });
});

describe("parseWorkPackageBlockExternalHTML", () => {
  it("returns undefined for a plain <div>", () => {
    expect(parseWorkPackageBlockExternalHTML(document.createElement("div"))).toBeUndefined();
  });

  it("returns undefined when data-block-content-type does not match", () => {
    const el = document.createElement("div");
    el.setAttribute("data-block-content-type", "somethingElse");
    expect(parseWorkPackageBlockExternalHTML(el)).toBeUndefined();
  });

  it("returns correct props from a valid element", () => {
    const el = document.createElement("div");
    el.setAttribute("data-block-content-type", "openProjectWorkPackageBlock");
    el.setAttribute("data-wpid", "42");
    el.setAttribute("data-instance-id", "inst1");
    el.setAttribute("data-size", "l");
    expect(parseWorkPackageBlockExternalHTML(el)).toEqual({ wpid: 42, instanceId: "inst1", size: "l" });
  });

  it("converts data-wpid to a number", () => {
    const el = document.createElement("div");
    el.setAttribute("data-block-content-type", "openProjectWorkPackageBlock");
    el.setAttribute("data-wpid", "99");
    expect(parseWorkPackageBlockExternalHTML(el)?.wpid).toBe(99);
  });

  it("falls back to size \"m\" when data-size is absent", () => {
    const el = document.createElement("div");
    el.setAttribute("data-block-content-type", "openProjectWorkPackageBlock");
    el.setAttribute("data-wpid", "1");
    expect(parseWorkPackageBlockExternalHTML(el)?.size).toBe("m");
  });
});

describe("round-trip: compute → build → parse", () => {
  it("recovers wpid (as number), instanceId, and size", () => {
    const data = computeWorkPackageBlockExternalData({ wpid: 42, instanceId: "inst1", size: "l" })!;
    const el = buildWorkPackageBlockExternalDOM(data, document);
    expect(parseWorkPackageBlockExternalHTML(el)).toEqual({ wpid: 42, instanceId: "inst1", size: "l" });
  });
});
