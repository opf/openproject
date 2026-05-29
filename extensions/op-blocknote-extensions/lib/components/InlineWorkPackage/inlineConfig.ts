export const inlineConfig = {
  type: "openProjectWorkPackageInline" as const,
  propSchema: {
    wpid: { default: "" },
    instanceId: { default: "" },
    size: { default: "s" },
  },
  content: "none" as const,
};
