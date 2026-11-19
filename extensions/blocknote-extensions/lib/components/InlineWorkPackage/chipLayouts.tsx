import { css } from 'styled-components';
import styled from 'styled-components';
import { CHIP_STYLES } from '../WorkPackage/tokens';
import { defaultWpVariables, nonSelectableStyles } from '../WorkPackage/atoms';

const chipBaseStyles = css`
  display: inline;
  border-radius: ${CHIP_STYLES.radius};
  background: ${CHIP_STYLES.bg};
  font-size: ${CHIP_STYLES.fontSize};
  box-decoration-break: clone;
  -webkit-box-decoration-break: clone;

  & > * {
    vertical-align: baseline;
  }

  & > *:not(:last-child) {
    margin-right: ${CHIP_STYLES.gap};
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

export const InlineChip = styled.span.attrs({
  className: 'op-bn-inline-wp',
  contentEditable: false,
})<{ selected?:boolean }>`
  ${defaultWpVariables}
  display: inline;
  cursor: pointer;
  ${nonSelectableStyles}
  border-radius: ${CHIP_STYLES.radius};
  position: relative;
  line-height: 1;

  &:active {
    cursor: grabbing;
  }

  ${({ selected }) =>
    selected &&
    css`
      & > .op-bn-inline-wp-base {
        box-shadow: ${CHIP_STYLES.inlineFocusShadow};
      }
    `}
`;
