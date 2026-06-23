import { css } from 'styled-components';
import styled from 'styled-components';
import { CHIP_STYLES } from '../WorkPackage/tokens';

const chipBaseStyles = css`
  display: inline;
  border-radius: ${CHIP_STYLES.radius};
  background: ${CHIP_STYLES.bg};
  font-size: ${CHIP_STYLES.fontSize};
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;

  /* gap equivalent for display:inline — applies left margin to every child except the first */
  & > * + * {
    margin-left: ${CHIP_STYLES.gap};
  }
`;

export const ChipBaseXXS = styled.span`
  ${chipBaseStyles}
  padding: ${CHIP_STYLES.padding.xxs};
`;

export const ChipBaseXS = styled.span`
  ${chipBaseStyles}
  padding: ${CHIP_STYLES.padding.xs};
`;

export const ChipBaseS = styled.span`
  ${chipBaseStyles}
  padding: ${CHIP_STYLES.padding.s};
`;

export const ChipBase = ChipBaseS;