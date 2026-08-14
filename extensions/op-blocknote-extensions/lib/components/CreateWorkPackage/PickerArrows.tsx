import styled from 'styled-components';
import { TriangleDownIcon, TriangleUpIcon } from '@primer/octicons-react';

// Octicons has no up and down pair, so it is composed of the two single ones.
const Arrows = styled.span`
  position: absolute;
  right: var(--spacer-l);
  display: flex;
  flex-direction: column;
  line-height: 0;
  pointer-events: none;
  color: var(--op-create-wp-arrow);

  svg:first-child {
    margin-bottom: -2px;
  }
`;

export const PickerArrows = () => (
  <Arrows>
    <TriangleUpIcon size={12} />
    <TriangleDownIcon size={12} />
  </Arrows>
);
