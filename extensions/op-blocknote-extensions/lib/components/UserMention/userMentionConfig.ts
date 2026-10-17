import { USER_MENTION_TYPE } from '../../utils/nodeTypes';

export const userMentionConfig = {
  type: USER_MENTION_TYPE,
  propSchema: {
    userId: { default: '' },
    name: { default: '' },
  },
  content: 'none' as const,
};
