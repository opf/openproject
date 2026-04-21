import { css } from "styled-components";
import styled from "styled-components";
import { CHIP_STYLES } from "../WorkPackage/tokens";

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

export const StatusChevron = () => (
  <svg
    aria-hidden="true"
    width={CHIP_STYLES.status.chevron.width}
    height={CHIP_STYLES.status.chevron.height}
    viewBox="0 0 8 5"
    fill="none"
    style={{ flexShrink: 0, display: "block" }}
  >
    <path d="M0 0L4 5L8 0H0Z" fill={CHIP_STYLES.status.chevron.color} />
  </svg>
);