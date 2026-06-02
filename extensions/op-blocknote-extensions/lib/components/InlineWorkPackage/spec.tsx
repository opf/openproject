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

    // toExternalHTML is used by two paths:
    //   1. renderHTML (TipTap/ProseMirror clipboard) — addInlineContentAttributes decorates
    //      the root DOM element with data-inline-content-type etc.
    //   2. External HTML exporter — InlineContentWrapper adds a span with the same attrs.
    // Using <a> as root in path 1 causes ProseMirror's Link mark parseDOM rule to fire on
    // paste, turning the chip back into a plain link.  A <span> root avoids that conflict
    // while still emitting a real hyperlink inside the span for external/markdown use.
    toExternalHTML: ({ inlineContent }) => {
      const data = computeWorkPackageInlineExternalData(inlineContent.props);
      if (!data) return <></>;
      return <span><a href={data.href}>{data.text}</a></span>;
    },

    parse: (element) => parseWorkPackageInlineExternalHTML(element),
    
    meta: {
      draggable: true,
    },
  }
);