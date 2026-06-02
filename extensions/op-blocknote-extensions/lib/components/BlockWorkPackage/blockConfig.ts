import { createBlockConfig } from "@blocknote/core";

export const blockConfig = createBlockConfig((() => ({
  type: "openProjectWorkPackageBlock" as const,
  propSchema: {
    wpid: { default: undefined, type: "number" },
    initialized: { default: false, type: "boolean" },
    size: { default: "m", type: "string" },
    instanceId: { default: "", type: "string" },
  },
  content: "none",
  isSelectable: false,
})) as unknown as ReturnType<typeof createBlockConfig>);
