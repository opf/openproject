import { useRef } from 'react';
import { useTranslation } from 'react-i18next';
import styled, { css } from 'styled-components';
import type { AnyEditor } from '../../editorTypes';
import { useIsNodeInSelection } from '../../hooks/useIsNodeInSelection';
import { useInlineNodeOptions } from '../../hooks/useInlineNodeOptions';
import { linkToUser } from '../../services/openProjectApi';
import { newTabLinkProps } from '../../utils/links';
import { USER_MENTION_TYPE } from '../../utils/nodeTypes';
import { OptionsPopover } from '../shared/OptionsPopover';
import { INLINE_NODE_STYLES, inlineNodeBaseStyles, inlineNodeContainerStyles } from '../shared/inlineNodeStyles';
import { Avatar } from '../shared/Avatar';
import type { UserMentionProps } from './externalHtml';

const PILL_PADDING = '2.5px 6px';
const AVATAR_SIZE = 16;
const AVATAR_INSET = '2px';
const AVATAR_GAP = '4px';

const Pill = styled.span.attrs({ className: 'op-bn-user-mention', contentEditable: false })<{ $selected:boolean }>`
  ${inlineNodeContainerStyles}
  ${inlineNodeBaseStyles}
  padding: ${PILL_PADDING};
  padding-left: ${AVATAR_INSET};

  /* text-bottom aligns the avatar's own box, so it does not move when the picture replaces the initials */
  & > .op-bn-avatar {
    vertical-align: text-bottom;
    margin-right: ${AVATAR_GAP};
  }

  ${({ $selected }) => $selected && css`box-shadow: ${INLINE_NODE_STYLES.inlineFocusShadow};`}
`;

const Name = styled.a`
  color: var(--bn-colors-editor-text);
  font-weight: 500;
  text-decoration: none;

  &:hover {
    text-decoration: underline;
  }
`;

interface UserMentionPillProps {
  props:UserMentionProps;
  editor:AnyEditor;
}

export function UserMentionPill({ props: { userId, name }, editor }:UserMentionPillProps) {
  const { t } = useTranslation();
  const pillRef = useRef<HTMLElement | null>(null);
  const selected = useIsNodeInSelection(pillRef, editor);
  const { optionsOpen, closeOptions, activationProps, removeNode } =
    useInlineNodeOptions(editor, pillRef, USER_MENTION_TYPE);
  const profileHref = linkToUser(userId);

  return (
    <Pill
      ref={pillRef}
      data-drag-handle
      role="button"
      aria-label={t('mention.ariaLabel', { name })}
      $selected={selected || optionsOpen}
      {...activationProps()}
    >
      <Avatar userId={userId} name={name} size={AVATAR_SIZE} />
      <Name {...newTabLinkProps(profileHref)}>
        {name}
      </Name>
      {optionsOpen && (
        <OptionsPopover
          // eslint-disable-next-line react-hooks/refs
          anchorEl={pillRef.current}
          openHref={profileHref}
          openAriaLabel={t('mention.openAriaLabel', { name })}
          removeAriaLabel={t('mention.removeAriaLabel')}
          onRemove={removeNode}
          onClose={closeOptions}
        />
      )}
    </Pill>
  );
}
