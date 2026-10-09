import styled, { css } from 'styled-components';
import {
  defaultColorStyles,
  typeTextColor,
} from '../../services/colors';
import { linkToWorkPackage } from '../../services/openProjectApi';
import { newTabLinkProps } from '../../utils/links';

/* lets a line break between two meta parts that are each kept unbroken  */
export const WRAP_OPPORTUNITY = '\u200B';

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
  overflow-wrap: anywhere;

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

export const workPackageLinkProps = (displayId:string) => newTabLinkProps(linkToWorkPackage(displayId));

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
