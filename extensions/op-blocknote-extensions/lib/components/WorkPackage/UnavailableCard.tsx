import styled from 'styled-components';
import { defaultWpVariables } from './atoms';

interface UnavailableCardProps {
  header:string;
  message:string;
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
`;

export const UnavailableCard = ({ header, message }:UnavailableCardProps) => (
  <UnavailableWorkPackage>
    <UnavailableMessage>
      <UnavailableMessageHeader>
        {header}
      </UnavailableMessageHeader>
      {message}
    </UnavailableMessage>
  </UnavailableWorkPackage>
);
