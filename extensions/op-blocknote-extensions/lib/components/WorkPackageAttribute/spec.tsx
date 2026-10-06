import { createReactInlineContentSpec } from '@blocknote/react';
import { attributeInlineConfig } from './inlineConfig';
import { WorkPackageAttributeChip } from './WorkPackageAttributeChip';
import { attributePropsOf } from './types';
import {
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from './externalHtml';

export const openProjectWorkPackageAttributeSpec = createReactInlineContentSpec(
  attributeInlineConfig,
  {
    render: ({ inlineContent, contentRef, editor, updateInlineContent }) => (
      <WorkPackageAttributeChip
        content={attributePropsOf(inlineContent.props)}
        editor={editor}
        contentRef={contentRef}
        onDisplayChange={(display) => updateInlineContent({
          type: attributeInlineConfig.type,
          props: { ...inlineContent.props, display },
        })}
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
