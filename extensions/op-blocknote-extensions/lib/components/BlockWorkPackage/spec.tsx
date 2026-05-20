import { createBlockConfig } from "@blocknote/core";
import { createReactBlockSpec } from "@blocknote/react";
import { BlockWorkPackageComponent } from "./BlockWorkPackage";

export const blockConfig = createBlockConfig((() => ({
  type: "openProjectWorkPackageBlock" as const,
  propSchema: {
    wpid: { default: undefined, type: "number" },
    initialized: { default: false, type: "boolean" },
    size: { default: "m", type: "string" },
  },
  content: "none",
  isSelectable: false,
})) as unknown as ReturnType<typeof createBlockConfig>);

export const openProjectWorkPackageBlockSpec = createReactBlockSpec(
  blockConfig,
  {
    render: (props) => (
      <BlockWorkPackageComponent
        block={props.block}
        editor={props.editor as any}
      />
    ),

    toExternalHTML: ({ block }) => {
      const { wpid, size, initialized } = block.props;
      if (!wpid) return <></>;
      return (
        <div
          data-block-content-type="openProjectWorkPackageBlock"
          data-wpid={String(wpid)}
          data-size={size ?? "m"}
          data-initialized={String(initialized ?? true)}
        >
          #{wpid}
        </div>
      );
    },

    parse: (element) => {
      if (element.getAttribute("data-block-content-type") !== "openProjectWorkPackageBlock") {
        return undefined;
      }
      const wpid = element.getAttribute("data-wpid");
      const size = element.getAttribute("data-size") ?? "m";
      return {
        wpid: wpid ? Number(wpid) : undefined,
        size,
        initialized: true,
      };
    },
  }
);