import { createBlockSpec } from '@blocknote/core';
import { attributeBlockConfig } from './blockConfig';
import {
  buildWorkPackageAttributeExternalDOM,
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from './externalHtml';

export const openProjectWorkPackageAttributeStaticBlockSpec = createBlockSpec(
  attributeBlockConfig,
  {
    render: (block) => {
      const data = computeWorkPackageAttributeExternalData(block.props, 'block');
      const dom = data ? buildWorkPackageAttributeExternalDOM(data, document) : document.createElement('div');
      return { dom };
    },

    toExternalHTML: (block) => {
      const data = computeWorkPackageAttributeExternalData(block.props, 'block');
      if (!data) return undefined;
      return { dom: buildWorkPackageAttributeExternalDOM(data, document) };
    },

    parse: (element) => parseWorkPackageAttributeExternalHTML(element, 'block'),
  }
);
