import { createInlineContentSpec } from '@blocknote/core';
import { attributeInlineConfig } from './inlineConfig';
import {
  buildWorkPackageAttributeExternalDOM,
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from './externalHtml';

export const openProjectWorkPackageAttributeStaticInlineSpec = createInlineContentSpec(
  attributeInlineConfig,
  {
    render: (inlineContent) => {
      const data = computeWorkPackageAttributeExternalData(inlineContent.props);
      const dom = data
        ? buildWorkPackageAttributeExternalDOM(data, document)
        : document.createElement('span');
      return { dom };
    },

    toExternalHTML: (inlineContent) => {
      const data = computeWorkPackageAttributeExternalData(inlineContent.props);
      if (!data) return undefined;
      return { dom: buildWorkPackageAttributeExternalDOM(data, document) };
    },

    parse: (element) => parseWorkPackageAttributeExternalHTML(element),
  }
);
