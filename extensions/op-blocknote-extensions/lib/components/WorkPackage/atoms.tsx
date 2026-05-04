import styled, { css } from "styled-components";
import {
  defaultColorStyles,
  typeTextColor,
} from "../../services/colors";

export const defaultWpVariables = css`
  --spacer-s: 4px;
  --spacer-m: 8px;
  --spacer-l: 12px;
  --spacer-xl: 16px;

  --lightness-threshold: 0.453;
  --background-alpha: 0.18;

  [data-color-scheme="dark"] & {
    --lightness-threshold: 0.6;
    --background-alpha: 0.10;
  }
`;

export const WorkPackageId = styled.div.attrs({
  className: "op-bn-work-package--id",
})<{ $compact?: boolean }>`
  color: var(--bn-colors-highlights-gray-text);

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 12px;
      font-weight: 400;
      flex-shrink: 0;
    `}
`;

export const WorkPackageType = styled.div.attrs({
  className: "op-bn-work-package--type",
  "data-testid": "op-bn-work-package--type",
})<{ $color: string; $compact?: boolean }>`
  ${({ $color }) => defaultColorStyles($color)}
  font-weight: ${({ $compact }) => ($compact ? 600 : 500)};
  text-transform: uppercase;
  color: ${typeTextColor} !important;

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 12px;
      flex-shrink: 0;
    `}
`;

export const WorkPackageStatus = styled.div.attrs({
  className: "op-bn-work-package--status",
})<{
  $baseColor: string;
  $borderColor?: string;
  $textColor?: string;
  $bgColor?: string;
  $compact?: boolean;
}>`
  ${({ $baseColor }) => defaultColorStyles($baseColor)}
  font-size: 0.95em;
  border-radius: 100px;
  border: 1px solid ${({ $borderColor }) => $borderColor ?? "transparent"};
  padding: 0 7px;
  align-content: center;
  color: ${({ $textColor }) => $textColor} !important;
  background-color: ${({ $bgColor }) => $bgColor};

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 12px;
      font-weight: 600;
      color: var(--bn-colors-editor-text) !important;
      flex-shrink: 0;
      display: inline-flex;
      align-items: center;
      gap: 4px;
      border: 1px solid var(--op-status-border-color);
    `}
`;

export const WorkPackageTitle = styled.div.attrs({
  className: "op-bn-work-package--title",
})<{ $compact?: boolean }>`
  flex-basis: max-content;
  color: var(--bn-colors-editor-text);
  font-weight: 500;

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 14px;
      font-weight: 600;
      color: var(--bn-colors-highlights-blue-text);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    `}
`;

export const WorkPackageTitleLink = styled.a<{ $compact?: boolean }>`
  cursor: pointer;
  text-decoration: none;
  color: var(--bn-colors-highlights-blue-text);

  &:hover {
    text-decoration: underline;
  }

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 14px;
      font-weight: 600;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    `}
`;