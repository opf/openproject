import styled from "styled-components";
import { TOKEN } from "./tokens";

// Chip base layouts (one per size for correct padding) 

const chipBaseStyles = `
  display: inline-flex;
  align-items: center;
  gap: ${TOKEN.chip.gap};
  border-radius: ${TOKEN.chip.radius};
  background: ${TOKEN.chip.bg};
  white-space: nowrap;
  max-width: 480px;
  overflow: hidden;
  font-size: ${TOKEN.fontSize};
`;

export const ChipBaseXXS = styled.span`${chipBaseStyles} padding: ${TOKEN.chip.padding.xxs};`;
export const ChipBaseXS = styled.span`${chipBaseStyles} padding: ${TOKEN.chip.padding.xs};`;
export const ChipBaseS = styled.span`${chipBaseStyles} padding: ${TOKEN.chip.padding.s};`;

// Fallback used in loading / error states
export const ChipBase = ChipBaseS;

// Text atoms 
export const IdAtom = styled.span`
  color: ${TOKEN.id.color};
  font-size: ${TOKEN.fontSize};
  font-weight: ${TOKEN.id.fontWeight};
  flex-shrink: 0;
`;

export const TypeAtom = styled.span`
  color: ${TOKEN.type.color};
  font-size: ${TOKEN.fontSize};
  font-weight: ${TOKEN.type.fontWeight};
  letter-spacing: ${TOKEN.type.letterSpacing};
  text-transform: ${TOKEN.type.textTransform};
  flex-shrink: 0;
`;

export const SubjectLink = styled.a`
  color: ${TOKEN.subject.color};
  font-size: ${TOKEN.fontSize};
  font-weight: ${TOKEN.subject.fontWeight};
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  text-decoration: none;

  &:hover { text-decoration: underline; }
`;

// Status pill 

export const StatusPill = styled.span`
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: ${TOKEN.status.padding};
  border-radius: ${TOKEN.status.radius};
  background: ${TOKEN.status.bg};
  border: ${TOKEN.status.border};
  color: ${TOKEN.status.color};
  font-size: ${TOKEN.fontSize};
  font-weight: ${TOKEN.status.fontWeight};
  flex-shrink: 0;
  line-height: 1.4;
`;

export const StatusChevron = () => (
  <svg
    aria-hidden="true"
    width={TOKEN.status.chevron.width}
    height={TOKEN.status.chevron.height}
    viewBox="0 0 8 5"
    fill="none"
    style={{ flexShrink: 0 }}
  >
    <path d="M0 0L4 5L8 0H0Z" fill={TOKEN.status.chevron.color} />
  </svg>
);