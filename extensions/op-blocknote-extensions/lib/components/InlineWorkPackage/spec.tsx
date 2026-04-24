import { createReactInlineContentSpec } from "@blocknote/react";
import { InlineWorkPackageChip } from "./InlineWorkPackageChip";

export const openProjectWorkPackageInlineSpec = createReactInlineContentSpec(
  {
    type: "openProjectWorkPackageInline" as const,
    propSchema: {
      wpid: { default: "" },
      instanceId: { default: "" },
      size: { default: "s" },
    },
    content: "none",
  },
  {
    render: ({ inlineContent, contentRef }) => (
      <InlineWorkPackageChip inlineContent={inlineContent} contentRef={contentRef} />
    ),

    toExternalHTML: ({ inlineContent }) => {
      const { wpid, instanceId, size } = inlineContent.props;
      if (!wpid || wpid.startsWith("pending:")) return <></>;
      return (
        <span
          data-inline-content-type="openProjectWorkPackageInline"
          data-wpid={wpid}
          data-instance-id={instanceId}
          data-size={size}
        >
          #{wpid}
        </span>
      );
    },
  }
);