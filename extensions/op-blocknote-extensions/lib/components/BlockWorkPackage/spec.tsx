import { createBlockConfig } from "@blocknote/core";
import { createReactBlockSpec } from "@blocknote/react";
import { BlockWorkPackageComponent } from "./BlockWorkPackage";

export const blockConfig = createBlockConfig((() => ({
  type: "openProjectWorkPackage",
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
  }
);