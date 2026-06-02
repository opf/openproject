// @vitest-environment jsdom
import { describe, it, expect } from "vitest";
import { openProjectWorkPackageStaticBlockSpec } from "../../../lib/components/BlockWorkPackage/staticSpec";
import { openProjectWorkPackageStaticInlineSpec } from "../../../lib/components/InlineWorkPackage/staticSpec";
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
  parseWorkPackageBlockExternalHTML,
} from "../../../lib/components/BlockWorkPackage/externalHtml";
import {
  computeWorkPackageInlineExternalData,
  buildWorkPackageInlineExternalDOM,
  parseWorkPackageInlineExternalHTML,
} from "../../../lib/components/InlineWorkPackage/externalHtml";

// The static spec wraps the same externalHtml functions in a BlockNote-compatible
// spec object (no React dependency). These tests verify that the spec's
// toExternalHTML and parse are consistent with the underlying functions so that
// Hocuspocus (server-side) and the React spec always produce identical HTML.

// createBlockSpec returns a creator function; call it to get the spec.
// createInlineContentSpec returns the spec directly.
const blockImpl = (openProjectWorkPackageStaticBlockSpec as any)().implementation;
const inlineImpl = (openProjectWorkPackageStaticInlineSpec as any).implementation;

describe("static block spec — toExternalHTML", () => {
  it("produces a DOM node matching buildWorkPackageBlockExternalDOM", () => {
    const props = { wpid: 42, instanceId: "inst1", size: "l" };
    const specResult = blockImpl.toExternalHTML({ props }) as { dom: HTMLElement } | undefined;
    const expected = buildWorkPackageBlockExternalDOM(computeWorkPackageBlockExternalData(props)!, document);
    // BlockNote wraps the returned dom in an outer block-content div;
    // the inner content is what our implementation produces.
    expect(specResult?.dom.innerHTML).toBe(expected.outerHTML);
  });

  it("returns undefined when wpid is absent", () => {
    expect(blockImpl.toExternalHTML({ props: {} })).toBeUndefined();
  });
});

describe("static block spec — parse", () => {
  it("delegates to parseWorkPackageBlockExternalHTML for a valid element", () => {
    const el = document.createElement("div");
    el.setAttribute("data-block-content-type", "openProjectWorkPackageBlock");
    el.setAttribute("data-wpid", "42");
    el.setAttribute("data-instance-id", "inst1");
    el.setAttribute("data-size", "l");
    expect(blockImpl.parse(el)).toEqual(parseWorkPackageBlockExternalHTML(el));
  });

  it("returns undefined for an unrelated element", () => {
    expect(blockImpl.parse(document.createElement("div"))).toBeUndefined();
  });
});

describe("static inline spec — toExternalHTML", () => {
  it("produces a DOM node matching buildWorkPackageInlineExternalDOM", () => {
    const props = { wpid: "57", instanceId: "inst1", size: "xs" };
    const specResult = inlineImpl.toExternalHTML({ props }) as { dom: HTMLElement } | undefined;
    const expected = buildWorkPackageInlineExternalDOM(computeWorkPackageInlineExternalData(props)!, document);
    expect(specResult?.dom.outerHTML).toBe(expected.outerHTML);
  });

  it("returns undefined for a pending wpid", () => {
    expect(inlineImpl.toExternalHTML({ props: { wpid: "pending:abc" } })).toBeUndefined();
  });

  it("returns undefined when wpid is absent", () => {
    expect(inlineImpl.toExternalHTML({ props: {} })).toBeUndefined();
  });
});

describe("static inline spec — parse", () => {
  it("delegates to parseWorkPackageInlineExternalHTML for a valid element", () => {
    const el = document.createElement("span");
    el.setAttribute("data-inline-content-type", "openProjectWorkPackageInline");
    el.setAttribute("data-wpid", "57");
    el.setAttribute("data-instance-id", "inst1");
    el.setAttribute("data-size", "xs");
    expect(inlineImpl.parse(el)).toEqual(parseWorkPackageInlineExternalHTML(el));
  });

  it("returns undefined for an unrelated element", () => {
    expect(inlineImpl.parse(document.createElement("span"))).toBeUndefined();
  });
});
