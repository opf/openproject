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

  /* Align ID, type, status and subject on the shared text baseline.
     Correct in Gecko (Firefox) and WebKit (Safari). */
  & > * {
    vertical-align: baseline;
  }

  /* Blink (Chrome/Edge) renders the smaller 12px ID/meta text too low with
     baseline alignment when mixed with the 14px subject, which also skewed the
     selection outline. */
  @supports (-webkit-app-region: drag) {
    & > * {
      vertical-align: middle;
    }
  }

  /* gap equivalent for display:inline — applies left margin to every child except the first */
  & > * + * {
    margin-left: ${CHIP_STYLES.gap};
  }
`;

export const ChipBaseXXS = styled.span.attrs({ className: 'op-bn-inline-wp-base' })`
  ${chipBaseStyles}
  padding: ${CHIP_STYLES.padding.xxs};
`;

export const ChipBaseXS = styled.span.attrs({ className: 'op-bn-inline-wp-base' })`
  ${chipBaseStyles}
  padding: ${CHIP_STYLES.padding.xs};
`;

export const ChipBaseS = styled.span.attrs({ className: 'op-bn-inline-wp-base' })`
  ${chipBaseStyles}
  padding: ${CHIP_STYLES.padding.s};
`;

export const ChipBase = ChipBaseS;