import { createReactInlineContentSpec } from '@blocknote/react';
import { attributeInlineConfig } from './inlineConfig';
import { WorkPackageAttributeInline } from './WorkPackageAttributeInline';
import { attributePropsOf } from './types';
import {
  computeWorkPackageAttributeExternalData,
  parseWorkPackageAttributeExternalHTML,
} from './externalHtml';

export const openProjectWorkPackageAttributeInlineSpec = createReactInlineContentSpec(
  attributeInlineConfig,
  {
    render: ({ inlineContent, contentRef, editor, updateInlineContent }) => (
      <WorkPackageAttributeInline
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
