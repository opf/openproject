import { INLINE_WP_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { ATTRIBUTE_DISPLAYS, DEFAULT_ATTRIBUTE_DISPLAY } from './display';

export const attributeInlineConfig = {
  type: INLINE_WP_ATTRIBUTE_TYPE,
  propSchema: {
    wpid: { default: '' },
    displayId: { default: '', type: 'string' },
    // The name the attribute macros resolve: an attribute key ("status")
    // or a custom field name ("Content owner").
    attribute: { default: '' },
    display: { default: DEFAULT_ATTRIBUTE_DISPLAY, values: ATTRIBUTE_DISPLAYS },
  },
  content: 'none' as const,
};
