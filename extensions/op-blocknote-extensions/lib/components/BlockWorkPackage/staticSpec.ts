import { createBlockSpec } from "@blocknote/core";
import { blockConfig } from "./blockConfig";
import {
  buildWorkPackageBlockExternalDOM,
  computeWorkPackageBlockExternalData,
  parseWorkPackageBlockExternalHTML,
} from "./externalHtml";

// Server-safe block spec. Same blockConfig and external-HTML shape as the
// React variant; only the runtime renderer is vanilla DOM. Suitable for
// @blocknote/server-util on Node (markdown export) without pulling
// @blocknote/react/react-dom into the import graph.
export const openProjectWorkPackageStaticBlockSpec = createBlockSpec(
  blockConfig,
  {
    render: (block) => {
      const data = computeWorkPackageBlockExternalData(block.props);
      const dom = data
        ? buildWorkPackageBlockExternalDOM(data, document)
        : document.createElement("div");
      return { dom };
    },

    toExternalHTML: (block) => {
      const data = computeWorkPackageBlockExternalData(block.props);
      if (!data) return undefined;
      const dom = buildWorkPackageBlockExternalDOM(data, document);
      return { dom };
    },

    parse: (element) => parseWorkPackageBlockExternalHTML(element),
  }
);
