import type { RefObject } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import type { Principal } from '../../openProjectTypes';
import type { SuggestionMenuComponent, SuggestionSearchState } from '../../hooks/useSuggestionSearch';
import { Avatar } from '../shared/Avatar';
import { SuggestionListbox } from '../shared/SuggestionListbox';

const AVATAR_SIZE = 24;

const Row = styled.span`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  padding: var(--spacer-s) 0;
  color: var(--bn-colors-editor-text);
`;

export function createMentionMenuComponent(
  searchStateRef:RefObject<SuggestionSearchState<Principal>>,
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
        optionKey={(principal) => principal.id}
        renderOption={(principal) => (
          <Row>
            <Avatar userId={principal.id} name={principal.name} size={AVATAR_SIZE} />
            {principal.name}
          </Row>
        )}
      />
    );
  };

  MentionMenu.displayName = 'MentionMenu';
  return MentionMenu;
}
