import { INLINE_WP_TYPE, USER_MENTION_TYPE } from '../../lib/utils/nodeTypes';

export function chipContent(wpid:string, size = 's') {
  return { type: INLINE_WP_TYPE, props: { wpid, size } };
}

export function mentionContent(userId:string, name:string) {
  return { type: USER_MENTION_TYPE, props: { userId, name } };
}

export function textContent(value:string) {
  return { type: 'text', text: value, styles: {} };
}

export function paragraphWith(...content:unknown[]) {
  return { type: 'paragraph', content };
}
