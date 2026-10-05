import styled from 'styled-components';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { defaultWpVariables, nonSelectableStyles } from '../WorkPackage/atoms';

const Chip = styled.span.attrs({
  className: 'op-bn-wp-attribute',
  contentEditable: false,
})`
  ${defaultWpVariables}
  ${nonSelectableStyles}
  display: inline;
  padding: ${CHIP_STYLES.padding.s};
  border-radius: ${CHIP_STYLES.radius};
  background: ${CHIP_STYLES.bg};
  font-size: ${CHIP_STYLES.fontSize};
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;
  cursor: pointer;
`;

export function WorkPackageAttributeChip({ attribute, displayId }:{ attribute:string, displayId:string }) {
  return <Chip title={displayId}>{attribute}</Chip>;
}
