import { INLINE_WP_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { ATTRIBUTE_DISPLAYS } from './display';

export const attributeInlineConfig = {
  type: INLINE_WP_ATTRIBUTE_TYPE,
  propSchema: {
    wpid: { default: '' },
    displayId: { default: '', type: 'string' },
    // The name the attribute macros resolve: an attribute key ("status")
    // or a custom field name ("Content owner").
    attribute: { default: '' },
    display: { default: 'value', values: ATTRIBUTE_DISPLAYS },
  },
  content: 'none' as const,
};
