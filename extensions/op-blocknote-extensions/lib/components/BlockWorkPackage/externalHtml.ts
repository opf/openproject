// Single source of truth for the HTML that both browser-side copy-to-clipboard
// and server-side markdown export emit for an openProjectWorkPackageBlock.
//
// Two surfaces:
// - computeWorkPackageBlockExternalData: pure transformation from block props
//   to the data needed to render external HTML. Used by both spec variants.
// - buildWorkPackageBlockExternalDOM: takes the data and builds an HTMLElement
//   via a provided Document. Used by the static (vanilla) spec.
//
// The React spec applies the same data via JSX so the produced HTML matches
// byte-for-byte.

import { buildExternalDOM } from "../WorkPackage/externalHtml";

export interface WorkPackageBlockProps {
  wpid?: number | string;
  instanceId?: string;
  size?: string;
}

export interface WorkPackageBlockExternalData {
  attrs: {
    "data-block-content-type": "openProjectWorkPackageBlock";
    "data-wpid": string;
    "data-instance-id": string;
    "data-size": string;
  };
  text: string;
}

export function computeWorkPackageBlockExternalData(
  props: WorkPackageBlockProps,
): WorkPackageBlockExternalData | null {
  const wpid = props.wpid;
  if (!wpid) return null;
  return {
    attrs: {
      "data-block-content-type": "openProjectWorkPackageBlock",
      "data-wpid": String(wpid),
      "data-instance-id": props.instanceId ?? "",
      "data-size": props.size ?? "m",
    },
    text: `#${wpid}`,
  };
}

export function buildWorkPackageBlockExternalDOM(
  data: WorkPackageBlockExternalData,
  doc: Document,
): HTMLElement {
  return buildExternalDOM("div", data.attrs, data.text, doc);
}

export function parseWorkPackageBlockExternalHTML(
  element: HTMLElement,
): WorkPackageBlockProps | undefined {
  if (element.getAttribute("data-block-content-type") !== "openProjectWorkPackageBlock") {
    return undefined;
  }
  const wpid = element.getAttribute("data-wpid");
  const instanceId = element.getAttribute("data-instance-id") ?? "";
  const size = element.getAttribute("data-size") ?? "m";
  return {
    wpid: wpid ? Number(wpid) : undefined,
    instanceId,
    size,
  };
}
