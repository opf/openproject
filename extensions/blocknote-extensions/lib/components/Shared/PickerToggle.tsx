import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { TriangleDownIcon, TriangleUpIcon } from '@primer/octicons-react';
import { TrailingButton } from './atoms';

const Glyph = styled.span`
  display: flex;
  flex-direction: column;
  line-height: 0;

  svg:first-child {
    margin-bottom: -2px;
  }
`;

interface PickerList {
  open:() => void;
  close:() => void;
  field:HTMLElement | null;
}

export function toggleList(next:boolean, { open, close, field }:PickerList):void {
  field?.focus();
  if (next) open();
  else close();
}

interface PickerToggleProps {
  isOpen:boolean;
  controls:string;
  testId:string;
  onToggle:(open:boolean) => void;
}

export const PickerToggle = ({ isOpen, controls, testId, onToggle }:PickerToggleProps) => {
  const { t } = useTranslation();

  return (
    <TrailingButton
      aria-label={t(isOpen ? 'createWorkPackage.closeOptions' : 'createWorkPackage.openOptions')}
      aria-expanded={isOpen}
      aria-controls={controls}
      data-testid={testId}
      onMouseDown={(event) => event.preventDefault()}
      onClick={() => onToggle(!isOpen)}
    >
      <Glyph>
        <TriangleUpIcon size={12} />
        <TriangleDownIcon size={12} />
      </Glyph>
    </TrailingButton>
  );
};
