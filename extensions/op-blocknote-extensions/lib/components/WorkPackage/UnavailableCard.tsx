import type { ReactNode } from 'react';
import styled from 'styled-components';
import { defaultWpVariables } from './atoms';
import { CHIP_STYLES } from './tokens';

interface UnavailableCardProps {
  header:string;
  message:string;
  icon?:ReactNode;
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

export const UnavailableCard = ({ header, message, icon }:UnavailableCardProps) => (
  <UnavailableWorkPackage>
    <UnavailableMessage>
      <UnavailableMessageHeader>
        {icon}
        {header}
      </UnavailableMessageHeader>
      {message}
    </UnavailableMessage>
  </UnavailableWorkPackage>
);
