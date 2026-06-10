import { createReactInlineContentSpec } from "@blocknote/react";
import { InlineWorkPackageChip } from "./InlineWorkPackageChip";
import { inlineConfig } from "./inlineConfig";
import {
  computeWorkPackageInlineExternalData,
  parseWorkPackageInlineExternalHTML,
} from "./externalHtml";

export const openProjectWorkPackageInlineSpec = createReactInlineContentSpec(
  inlineConfig,
  {
    render: ({ inlineContent, contentRef, editor }) => (
      <InlineWorkPackageChip inlineContent={inlineContent} contentRef={contentRef} editor={editor}/>
    ),

    // BlockNote's InlineContentWrapper already wraps this output in a span carrying
    // data-inline-content-type, data-wpid, and data-instance-id from the prop schema.
    // data-size is also serialised onto the outer span for non-default values by BlockNote.
    // Returning just the text avoids a duplicate inner span with the same attributes.
    toExternalHTML: ({ inlineContent }) => {
      const data = computeWorkPackageInlineExternalData(inlineContent.props);
      if (!data) return <></>;
      return <>{data.text}</>;
    },

    parse: (element) => parseWorkPackageInlineExternalHTML(element),
    
    meta: {
      draggable: true,
    },
  }
);