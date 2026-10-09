import { css } from 'styled-components';
import styled from 'styled-components';
import { INLINE_NODE_STYLES, inlineNodeBaseStyles, inlineNodeContainerStyles } from '../shared/inlineNodeStyles';

export const ChipBaseXXS = styled.span.attrs({ className: 'op-bn-inline-wp-base' })`
  ${inlineNodeBaseStyles}
  padding: ${INLINE_NODE_STYLES.padding.xxs};
`;

export const ChipBaseXS = styled.span.attrs({ className: 'op-bn-inline-wp-base' })`
  ${inlineNodeBaseStyles}
  padding: ${INLINE_NODE_STYLES.padding.xs};
`;

export const ChipBaseS = styled.span.attrs({ className: 'op-bn-inline-wp-base' })`
  ${inlineNodeBaseStyles}
  padding: ${INLINE_NODE_STYLES.padding.s};
`;

export const ChipBase = ChipBaseS;

export const InlineChip = styled.span.attrs({
  className: 'op-bn-inline-wp',
  contentEditable: false,
})<{ selected?:boolean }>`
  ${inlineNodeContainerStyles}

  &:active {
    cursor: grabbing;
  }

  ${({ selected }) =>
    selected &&
    css`
      & > .op-bn-inline-wp-base {
        box-shadow: ${INLINE_NODE_STYLES.inlineFocusShadow};
      }
    `}
`;
