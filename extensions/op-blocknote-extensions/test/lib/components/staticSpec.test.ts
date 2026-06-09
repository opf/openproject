// @vitest-environment jsdom
import { describe, it, expect } from "vitest";
import { openProjectWorkPackageStaticBlockSpec } from "../../../lib/components/BlockWorkPackage/staticSpec";
import { openProjectWorkPackageStaticInlineSpec } from "../../../lib/components/InlineWorkPackage/staticSpec";
import {
  computeWorkPackageBlockExternalData,
  buildWorkPackageBlockExternalDOM,
} from "../../../lib/components/BlockWorkPackage/externalHtml";
import {
  computeWorkPackageInlineExternalData,
  buildWorkPackageInlineExternalDOM,
} from "../../../lib/components/InlineWorkPackage/externalHtml";
import {openProjectWorkPackageBlockSpec, openProjectWorkPackageInlineSpec} from "../../../lib";

// The static spec wraps the same externalHtml functions in a BlockNote-compatible
// spec object (no React dependency). These tests verify that the spec's
// toExternalHTML and parse are consistent with the underlying functions so that
// Hocuspocus (server-side) and the React spec always produce identical HTML.

// createBlockSpec returns a creator function; call it to get the spec.
// createInlineContentSpec returns the spec directly.
const blockImpl = (openProjectWorkPackageStaticBlockSpec as any)().implementation;
const reactBlockImpl = (openProjectWorkPackageBlockSpec as any)().implementation;
const inlineImpl = (openProjectWorkPackageStaticInlineSpec as any).implementation;
const reactInlineImpl = (openProjectWorkPackageInlineSpec as any).implementation;

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
  const makeBlockElement = () => {
    const element = document.createElement("div");
    element.setAttribute("data-block-content-type", "openProjectWorkPackageBlock");
    element.setAttribute("data-wpid", "42");
    element.setAttribute("data-instance-id", "inst1");
    element.setAttribute("data-size", "l");
    return element;
  };

  it("parses the HTML element", () => {
    const element = makeBlockElement();
    expect(blockImpl.parse(element)).toEqual({ wpid: 42, instanceId: "inst1", size: "l" });
  });

  it("parses the HTML element in the same way as the react block spec", () => {
    const element = makeBlockElement();
    expect(blockImpl.parse(element)).toEqual(reactBlockImpl.parse(element));
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
  const makeInlineElement = () => {
    const element = document.createElement("span");
    element.setAttribute("data-inline-content-type", "openProjectWorkPackageInline");
    element.setAttribute("data-wpid", "57");
    element.setAttribute("data-instance-id", "inst1");
    element.setAttribute("data-size", "xs");
    return element;
  };

  it("parses the HTML element", () => {
    const element = makeInlineElement();
    expect(inlineImpl.parse(element)).toEqual({ wpid: "57", instanceId: "inst1", size: "xs" });
  });

  it("parses the HTML element in the same way as the react inline spec", () => {
    const element = makeInlineElement();
    expect(inlineImpl.parse(element)).toEqual(reactInlineImpl.parse(element));
  });

  it("returns undefined for an unrelated element", () => {
    expect(inlineImpl.parse(document.createElement("span"))).toBeUndefined();
  });
});
