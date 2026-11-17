import { PlusIcon } from '@primer/octicons-react';
import { useTranslation } from 'react-i18next';
import styled from 'styled-components';

const Option = styled.div.attrs({
  className: 'op-bn-search--create',
  'data-testid': 'create-wp-option',
})`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  padding: var(--spacer-m) 0;
  color: var(--bn-colors-editor-text, #333);
`;

/** The last entry of a work package search, offering to create what was not found. */
export const CreateWorkPackageOption = () => {
  const { t } = useTranslation();

  return (
    <Option>
      <PlusIcon size={16} />
      <span>{t('search.createWorkPackage')}</span>
    </Option>
  );
};
