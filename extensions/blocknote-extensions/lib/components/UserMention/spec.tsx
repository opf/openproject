import { createReactInlineContentSpec } from '@blocknote/react';
import { userMentionConfig } from './userMentionConfig';
import { userMentionTag, parseUserMentionExternalHTML } from './externalHtml';
import { UserMentionPill } from './UserMentionPill';

export const openProjectUserMentionSpec = createReactInlineContentSpec(
  userMentionConfig,
  {
    render: ({ inlineContent, editor }) => <UserMentionPill props={inlineContent.props} editor={editor} />,

    // A <span> root for the same reason as the work package chip: an <a> or
    // unknown root lets the Link mark claim the node on paste.
    toExternalHTML: ({ inlineContent }) => {
      if (!inlineContent.props.userId) return <></>;
      return <span dangerouslySetInnerHTML={{ __html: userMentionTag(inlineContent.props) }} />;
    },

    parse: (element) => parseUserMentionExternalHTML(element),

    meta: {
      draggable: true,
    },
  }
);
