import type { ReactNode } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { editorThemeVariables, NODE_CONTENT_GAP } from '../shared/theme';
import {
  WorkPackageId,
  WorkPackageTitleLink,
  workPackageLinkProps,
} from './atoms';
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
  ${editorThemeVariables}
  padding: var(--spacer-m) var(--spacer-l);
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
  gap: ${NODE_CONTENT_GAP};
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
              ? (
                <WorkPackageTitleLink
                  {...workPackageLinkProps(displayId)}
                  onClick={(event) => event.stopPropagation()}
                >
                  {header}
                </WorkPackageTitleLink>
              )
              : header}
          </span>
        </UnavailableMessageHeader>
        {t(messageKey)}
      </UnavailableMessage>
    </UnavailableWorkPackage>
  );
};
