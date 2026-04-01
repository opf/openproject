import { createReactInlineContentSpec } from "@blocknote/react";
import { InlineWorkPackageChip } from "./InlineWorkPackageChip";
import { linkToWorkPackage } from "../../services/openProjectApi";

export const inlineWorkPackageSpec = createReactInlineContentSpec(
  {
    type: "inlineWorkPackage" as const,
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
        <a
          href={linkToWorkPackage(Number(wpid))}
          target="_blank"
          rel="noopener noreferrer"
          data-inline-wp={wpid}
          data-inline-wp-instance={instanceId}
          data-inline-wp-size={size ?? "s"}
        >
          #{wpid}
        </a>
      );
    },
  }
);