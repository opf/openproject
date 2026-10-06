import { BLOCK_ATTRIBUTE_TYPE } from '../../utils/nodeTypes';
import { attributeInlineConfig } from './inlineConfig';

export const attributeBlockConfig = {
  type: BLOCK_ATTRIBUTE_TYPE,
  propSchema: attributeInlineConfig.propSchema,
  content: 'none' as const,
};
