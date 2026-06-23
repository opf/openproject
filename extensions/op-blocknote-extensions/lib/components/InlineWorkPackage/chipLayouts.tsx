import { css } from 'styled-components';
import styled from 'styled-components';
import { CHIP_STYLES } from '../WorkPackage/tokens';

const chipBaseStyles = css`
  display: inline-flex;
  align-items: center;
  gap: ${CHIP_STYLES.gap};
  border-radius: ${CHIP_STYLES.radius};
  background: ${CHIP_STYLES.bg};
  white-space: nowrap;
  max-width: 480px;
  overflow: hidden;
  font-size: ${CHIP_STYLES.fontSize};
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