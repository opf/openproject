import { createInlineContentSpec } from '@blocknote/core';
import { inlineConfig } from './inlineConfig';
import {
  buildWorkPackageInlineExternalDOM,
  computeWorkPackageInlineExternalData,
  parseWorkPackageInlineExternalHTML,
} from './externalHtml';

// Server-safe inline content spec. Same inlineConfig and external-HTML shape
// as the React variant; only the runtime renderer is vanilla DOM. Suitable for
// @blocknote/server-util on Node (markdown export) without pulling
// @blocknote/react/react-dom into the import graph.
export const openProjectWorkPackageStaticInlineSpec = createInlineContentSpec(
  inlineConfig,
  {
    render: (inlineContent) => {
      const data = computeWorkPackageInlineExternalData(inlineContent.props);
      const dom = data
        ? buildWorkPackageInlineExternalDOM(data, document)
        : document.createElement('span');
      return { dom };
    },

    toExternalHTML: (inlineContent) => {
      const data = computeWorkPackageInlineExternalData(inlineContent.props);
      if (!data) return undefined;
      return { dom: buildWorkPackageInlineExternalDOM(data, document) };
    },

    parse: (element) => parseWorkPackageInlineExternalHTML(element),
  }
);
