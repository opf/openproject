import type { RefObject } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import type { MentionableUser } from '../../openProjectTypes';
import type { SuggestionMenuComponent, SuggestionSearchState } from '../../hooks/useSuggestionSearch';
import { Avatar } from '../Shared/Avatar';
import { SuggestionListbox } from '../Shared/SuggestionListbox';

const AVATAR_SIZE = 24;

const Row = styled.span`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  padding: var(--spacer-s) 0;
  color: var(--bn-colors-editor-text);
`;

export function createMentionMenuComponent(
  searchStateRef:RefObject<SuggestionSearchState<MentionableUser>>,
):SuggestionMenuComponent {
  const MentionMenu:SuggestionMenuComponent = (props) => {
    const { t } = useTranslation();

    return (
      <SuggestionListbox
        {...props}
        name="mention-menu"
        ariaLabel={t('mentionMenu.ariaLabel')}
        loadingMessage={t('mentionMenu.loading')}
        searchState={searchStateRef.current}
        optionKey={(user) => user.id}
        renderOption={(user) => (
          <Row>
            <Avatar userId={user.id} name={user.name} size={AVATAR_SIZE} />
            {user.name}
          </Row>
        )}
      />
    );
  };

  MentionMenu.displayName = 'MentionMenu';
  return MentionMenu;
}
