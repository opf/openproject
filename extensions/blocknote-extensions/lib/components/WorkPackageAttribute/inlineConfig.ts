export const attributeInlineConfig = {
  type: 'openProjectWorkPackageAttributeInline' as const,
  propSchema: {
    wpid: { default: '' },
    displayId: { default: '', type: 'string' },
    // The name the attribute macros resolve: an attribute key ("status")
    // or a custom field name ("Content owner").
    attribute: { default: '' },
    display: { default: 'value', values: ['label', 'value', 'both'] },
  },
  content: 'none' as const,
};
