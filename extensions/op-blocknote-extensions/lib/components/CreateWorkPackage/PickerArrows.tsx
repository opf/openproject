import styled from 'styled-components';
import { TriangleDownIcon, TriangleUpIcon } from '@primer/octicons-react';

// Octicons has no up and down pair, so it is composed of the two single ones.
const Glyph = styled.span`
  display: flex;
  flex-direction: column;
  line-height: 0;

  svg:first-child {
    margin-bottom: -2px;
  }
`;

export const PickerArrowsGlyph = () => (
  <Glyph>
    <TriangleUpIcon size={12} />
    <TriangleDownIcon size={12} />
  </Glyph>
);
