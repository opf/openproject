import { escapeHtmlAttribute, escapeHtmlText } from '../../utils/html';
import { USER_MENTION_TYPE } from '../../utils/nodeTypes';

export interface UserMentionProps {
  userId:string;
  name:string;
}

/** The exact markup OpenProject stores for a user mention (see Users::ReplaceMentionsService). */
export function userMentionTag({ userId, name }:UserMentionProps):string {
  const text = `@${name}`;
  return `<mention class="mention" data-id="${escapeHtmlAttribute(userId)}" data-type="user" `
    + `data-text="${escapeHtmlAttribute(text)}">${escapeHtmlText(text)}</mention>`;
}

function wrapperAttributes({ userId, name }:UserMentionProps):Record<string, string> {
  return {
    'data-inline-content-type': USER_MENTION_TYPE,
    'data-user-id': userId,
    'data-name': name,
  };
}

export function buildUserMentionStoredDOM(props:UserMentionProps, document:Document):HTMLElement {
  const wrapper = document.createElement('span');
  for (const [attribute, value] of Object.entries(wrapperAttributes(props))) {
    wrapper.setAttribute(attribute, value);
  }
  wrapper.textContent = userMentionTag(props);
  return wrapper;
}

export function parseUserMentionExternalHTML(element:HTMLElement):UserMentionProps | undefined {
  // BlockNote's own wrapper omits the props at their default, so one without a user id is left to its content.
  if (element.getAttribute('data-inline-content-type') === USER_MENTION_TYPE && element.hasAttribute('data-user-id')) {
    return {
      userId: element.getAttribute('data-user-id') ?? '',
      name: element.getAttribute('data-name') ?? '',
    };
  }

  const userId = element.getAttribute('data-id');
  if (element.tagName.toLowerCase() === 'mention' && element.getAttribute('data-type') === 'user' && userId) {
    return {
      userId,
      name: (element.getAttribute('data-text') ?? '').replace(/^@/, ''),
    };
  }

  return undefined;
}
