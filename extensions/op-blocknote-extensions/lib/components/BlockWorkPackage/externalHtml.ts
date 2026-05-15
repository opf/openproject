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

export interface WorkPackageBlockProps {
  wpid?: number | string;
  size?: string;
  initialized?: boolean;
}

export interface WorkPackageBlockExternalData {
  attrs: {
    "data-block-content-type": "openProjectWorkPackageBlock";
    "data-wpid": string;
    "data-size": string;
    "data-initialized": string;
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
      "data-size": props.size ?? "m",
      "data-initialized": String(props.initialized ?? true),
    },
    text: `#${wpid}`,
  };
}

export function buildWorkPackageBlockExternalDOM(
  data: WorkPackageBlockExternalData,
  doc: Document,
): HTMLElement {
  const div = doc.createElement("div");
  for (const [name, value] of Object.entries(data.attrs)) {
    div.setAttribute(name, value);
  }
  div.textContent = data.text;
  return div;
}

export function parseWorkPackageBlockExternalHTML(
  element: HTMLElement,
): WorkPackageBlockProps | undefined {
  if (element.getAttribute("data-block-content-type") !== "openProjectWorkPackageBlock") {
    return undefined;
  }
  const wpid = element.getAttribute("data-wpid");
  const size = element.getAttribute("data-size") ?? "m";
  return {
    wpid: wpid ? Number(wpid) : undefined,
    size,
    initialized: true,
  };
}
