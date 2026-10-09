import { createInlineContentSpec } from '@blocknote/core';
import { userMentionConfig } from './userMentionConfig';
import { buildUserMentionStoredDOM, parseUserMentionExternalHTML } from './externalHtml';

// Only the hocuspocus server uses this spec, and only to store markdown.
export const openProjectUserMentionStaticSpec = createInlineContentSpec(
  userMentionConfig,
  {
    render: (inlineContent) => {
      const dom = document.createElement('span');
      dom.textContent = `@${inlineContent.props.name}`;
      return { dom };
    },

    toExternalHTML: (inlineContent) => {
      if (!inlineContent.props.userId) return undefined;
      return { dom: buildUserMentionStoredDOM(inlineContent.props, document) };
    },

    parse: (element) => parseUserMentionExternalHTML(element),
  }
);
