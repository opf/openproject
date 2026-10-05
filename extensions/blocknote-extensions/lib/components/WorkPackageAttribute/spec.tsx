import { createReactInlineContentSpec } from '@blocknote/react';
import { attributeInlineConfig } from './inlineConfig';
import { WorkPackageAttributeChip } from './WorkPackageAttributeChip';
import {
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from './externalHtml';

export const openProjectWorkPackageAttributeSpec = createReactInlineContentSpec(
  attributeInlineConfig,
  {
    render: ({ inlineContent }) => (
      <WorkPackageAttributeChip
        attribute={inlineContent.props.attribute}
        displayId={inlineContent.props.displayId || inlineContent.props.wpid}
      />
    ),

    toExternalHTML: ({ inlineContent }) => {
      const data = computeWorkPackageAttributeExternalData(inlineContent.props);
      if (!data) return <></>;
      return <span>{data.text}</span>;
    },

    parse: (element) => parseWorkPackageAttributeExternalHTML(element),

    meta: {
      draggable: true,
    },
  }
);
