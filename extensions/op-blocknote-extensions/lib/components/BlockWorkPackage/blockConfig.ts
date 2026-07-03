import { createBlockConfig } from '@blocknote/core';

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
