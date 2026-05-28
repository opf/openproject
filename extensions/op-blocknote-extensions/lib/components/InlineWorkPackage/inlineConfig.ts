export const inlineConfig = {
  type: 'openProjectWorkPackageInline' as const,
  propSchema: {
    wpid: { default: '' },
    instanceId: { default: '' },
    size: { default: 's' },
    displayId: { default: '', type: 'string' },
  },
  content: 'none' as const,
};
