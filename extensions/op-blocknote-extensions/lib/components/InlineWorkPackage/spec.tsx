import { createReactInlineContentSpec } from "@blocknote/react";
import { InlineWorkPackageChipInEditor } from "./InlineWorkPackageChipInEditor";

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
      <InlineWorkPackageChipInEditor inlineContent={inlineContent} contentRef={contentRef} />
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

    parse: (element) => {
      if (element.getAttribute("data-inline-content-type") !== "openProjectWorkPackageInline") {
        return undefined;
      }
      return {
        wpid: element.getAttribute("data-wpid") ?? "",
        instanceId: element.getAttribute("data-instance-id") ?? "",
        size: element.getAttribute("data-size") ?? "s",
      };
    },

    meta: {
      draggable: true,
    },
  }
);