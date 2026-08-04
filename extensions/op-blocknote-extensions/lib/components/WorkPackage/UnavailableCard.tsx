import type { ReactNode } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import {
  defaultWpVariables,
  WorkPackageId,
  WorkPackageTitleLink,
  workPackageLinkProps,
} from './atoms';
import { CHIP_STYLES } from './tokens';
import { formatWorkPackageId } from '../../utils/id';

interface UnavailableCardProps {
  headerKey:string;
  messageKey:string;
  icon?:ReactNode;
  displayId?:string;
  linkHeader?:boolean;
}

const UnavailableWorkPackage = styled.div.attrs({
  className: 'op-bn-work-package-placeholder',
})`
  ${defaultWpVariables}
  padding: var(--spacer-m) var(--spacer-l);
  background-color: var(--highlight-wp-background);
  border-radius: var(--bn-border-radius-small);
`;

const UnavailableMessage = styled.div.attrs({
  className: 'op-bn-unavailable-message',
})`
  color: var(--bn-colors-editor-text) !important;
`;

const UnavailableMessageHeader = styled.div.attrs({
  className: 'op-bn-unavailable-message--header',
})`
  font-weight: 600;
  color: var(--bn-colors-editor-text) !important;
  display: flex;
  align-items: center;
  gap: ${CHIP_STYLES.gap};
`;

export const UnavailableCard = ({ headerKey, messageKey, icon, displayId, linkHeader }:UnavailableCardProps) => {
  const { t } = useTranslation();

  const header = t(headerKey);

  return (
    <UnavailableWorkPackage>
      <UnavailableMessage>
        <UnavailableMessageHeader>
          {icon}
          {displayId && <WorkPackageId as="span" $compact>{formatWorkPackageId(displayId)}</WorkPackageId>}
          <span>
            {linkHeader && displayId
              ? <WorkPackageTitleLink {...workPackageLinkProps(displayId)}>{header}</WorkPackageTitleLink>
              : header}
          </span>
        </UnavailableMessageHeader>
        {t(messageKey)}
      </UnavailableMessage>
    </UnavailableWorkPackage>
  );
};
