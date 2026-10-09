import { INLINE_WP_TYPE } from '../../utils/nodeTypes';

export const inlineConfig = {
  type: INLINE_WP_TYPE,
  propSchema: {
    wpid: { default: '' },
    size: { default: 's' },
    displayId: { default: '', type: 'string' },
  },
  content: 'none' as const,
};
