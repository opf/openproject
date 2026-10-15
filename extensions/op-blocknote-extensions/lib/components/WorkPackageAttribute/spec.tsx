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
        wpid={inlineContent.props.wpid}
        displayId={inlineContent.props.displayId || inlineContent.props.wpid}
        attribute={inlineContent.props.attribute}
        display={inlineContent.props.display}
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
