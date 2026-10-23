import type { RefObject } from 'react';
import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import type { SuggestionMenuComponent, SuggestionSearchState } from '../../hooks/useSuggestionSearch';
import { BlockCard } from '../BlockWorkPackage/BlockCard';
import { SuggestionListbox } from '../shared/SuggestionListbox';

export function createHashWpMenuComponent(
  searchStateRef:RefObject<SuggestionSearchState<WorkPackage>>,
):SuggestionMenuComponent {
  const HashWpMenuComponent:SuggestionMenuComponent = (props) => {
    const { t } = useTranslation();

    return (
      <SuggestionListbox
        {...props}
        name="hash-menu"
        ariaLabel={t('search.dropdownAriaLabel')}
        loadingMessage={t('hashMenu.typeToSearch')}
        searchState={searchStateRef.current}
        promptMessage={t('hashMenu.typeToSearch')}
        optionKey={(workPackage) => workPackage.id}
        renderOption={(workPackage) => <BlockCard workPackage={workPackage} inDropdown />}
      />
    );
  };

  HashWpMenuComponent.displayName = 'HashWpMenu';
  return HashWpMenuComponent;
}
