import { defaultVariables } from "../services/colors.ts";
import styled from "styled-components";

export const UnavailableWorkPackageElement = ({ header, message }: {header: string, message: string}) => {
  return (
    <UnavailableWorkPackage>
      <UnavailableMessage>
        <UnavailableMessageHeader>
          { header }
        </UnavailableMessageHeader>
        { message }
      </UnavailableMessage>
    </UnavailableWorkPackage>
  )
}

const UnavailableWorkPackage = styled.div.attrs({
  className: 'op-bn-work-package-placeholder'
})`
  ${defaultVariables}
  padding: var(--spacer-m) var(--spacer-l);
  background-color: var(--highlight-wp-background);
  border-radius: var(--bn-border-radius-small);
`;

const UnavailableMessage = styled.div.attrs({
  className: 'op-bn-unavailable-message'
})`
  color: var(--bn-colors-editor-text) !important;
`

const UnavailableMessageHeader = styled.div.attrs({
  className: 'op-bn-unavailable-message--header'
})`
  font-weight: 600;
  color: var(--bn-colors-editor-text) !important;
`
