import { createBlockConfig } from '@blocknote/core';

// The cast keeps the generics wide - inferred ones narrow props to the literal
// prop schema, which the spec renderers and externalHtml are not typed for.
// eslint-disable-next-line @typescript-eslint/no-unnecessary-type-assertion
export const blockConfig = createBlockConfig((() => ({
  type: 'openProjectWorkPackageBlock' as const,
  propSchema: {
    wpid: { default: undefined, type: 'number' },
    size: { default: 'm', type: 'string' },
    displayId: { default: '', type: 'string' },
  },
  content: 'none',
  isSelectable: false,
})) as unknown as ReturnType<typeof createBlockConfig>);
