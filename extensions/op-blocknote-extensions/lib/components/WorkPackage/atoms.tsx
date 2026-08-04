import type { MouseEvent } from 'react';
import styled, { css } from 'styled-components';
import {
  defaultColorStyles,
  metaTextColor,
  typeTextColor,
} from '../../services/colors';
import { linkToWorkPackage } from '../../services/openProjectApi';

export const defaultWpVariables = css`
  --spacer-s: 4px;
  --spacer-m: 8px;
  --spacer-l: 12px;
  --spacer-xl: 16px;

  /* BlockNote's node-selection outline color; not exposed by BlockNote as a variable, so defined here */
  --blocknote-focus-color: rgb(100, 160, 255);

  --lightness-threshold: 0.453;
  --background-alpha: 0.18;

  --op-chip-bg: var(--bn-colors-highlights-gray-background);
  --op-item-hover-bg: var(--bn-colors-highlights-gray-background, #f0f0f0);
  --op-wp-meta-color: ${metaTextColor};

  [data-color-scheme="dark"] & {
    --lightness-threshold: 0.6;
    --background-alpha: 0.10;
    --op-chip-bg: var(--bn-colors-disabled-text);
    --op-item-hover-bg: rgba(255, 255, 255, 0.12);
  }
`;

export const WorkPackageId = styled.span.attrs({
  className: 'op-bn-work-package--id',
})<{ $compact?:boolean }>`
  color: var(--op-wp-meta-color) !important;
  white-space: nowrap;

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 12px;
      font-weight: 400;
    `}
`;

export const WorkPackageType = styled.span.attrs({
  className: 'op-bn-work-package--type',
  'data-testid': 'op-bn-work-package--type',
})<{ $color:string; $compact?:boolean }>`
  ${({ $color }) => defaultColorStyles($color)}
  font-weight: ${({ $compact }) => ($compact ? 600 : 500)};
  text-transform: uppercase;
  color: ${typeTextColor} !important;
  white-space: nowrap;

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 12px;
    `}
`;

export const WorkPackageStatus = styled.span.attrs({
  className: 'op-bn-work-package--status',
})<{
  $baseColor:string;
  $borderColor?:string;
  $textColor?:string;
  $bgColor?:string;
  $compact?:boolean;
}>`
  ${({ $baseColor }) => defaultColorStyles($baseColor)}
  font-size: 0.95em;
  border-radius: 100px;
  border: 1px solid ${({ $borderColor }) => $borderColor ?? 'transparent'};
  padding: 0 7px;
  color: ${({ $textColor }) => $textColor} !important;
  background-color: ${({ $bgColor }) => $bgColor};
  white-space: nowrap;

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 12px;
      font-weight: 600;
      display: inline-flex;
      align-items: center;
    `}
`;

export const WorkPackageTitle = styled.span.attrs({
  className: 'op-bn-work-package--title',
})`
  color: var(--bn-colors-editor-text);
  font-weight: 500;
  overflow-wrap: anywhere;
`;

export const workPackageLinkProps = (displayId:string) => ({
  href: linkToWorkPackage(displayId),
  target: '_blank' as const,
  rel: 'noopener noreferrer',
  /*  keep link clicks from toggling the surrounding chip/card popover  */
  onClick: (e:MouseEvent) => e.stopPropagation(),
});

export const WorkPackageTitleLink = styled.a<{ $compact?:boolean }>`
  cursor: pointer;
  text-decoration: none;
  color: var(--bn-colors-highlights-blue-text);
  overflow-wrap: anywhere;

  &:hover {
    text-decoration: underline;
  }

  ${({ $compact }) =>
    $compact &&
    css`
      font-size: 14px;
      font-weight: 600;
    `}
`;