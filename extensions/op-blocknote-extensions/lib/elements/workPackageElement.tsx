import type { WorkPackage } from "../openProjectTypes";
import {
  defaultColorStyles,
  defaultVariables,
  statusBackgroundColor,
  statusColor,
  statusBorderColor,
  statusTextColor,
  typeColor,
  typeTextColor
} from "../services/colors.ts";
import styled from "styled-components";
import { linkToWorkPackage } from "../services/openProjectApi";
import { forwardRef } from "react";

interface WorkPackageElementProps {
  workPackage: WorkPackage;
  inDropdown?: boolean;
  linkTitle?: boolean;
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
}

export const WorkPackageElement = forwardRef<HTMLDivElement, WorkPackageElementProps>(
  ({ workPackage, inDropdown = false, linkTitle = false, onClick }, ref) => {
    const title = linkTitle ? (
      <WorkPackageTitleLink
        href={linkToWorkPackage(workPackage.id)}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
          window.open(linkToWorkPackage(workPackage.id), "_blank", "noopener,noreferrer");
        }}
      >
        {workPackage.subject}
      </WorkPackageTitleLink>
    ) : (
      workPackage.subject
    );

    return (
      <WorkPackageCard
        ref={ref}
        $inDropdown={inDropdown}
        onClick={onClick}
        style={onClick ? { cursor: "pointer" } : undefined}
      >
        <WorkPackageDetails>
          <WorkPackageType $color={typeColor(workPackage)}>
            {workPackage._links?.type?.title}
          </WorkPackageType>
          <WorkPackageId>#{workPackage.id}</WorkPackageId>
          <WorkPackageStatus
            $baseColor={statusColor(workPackage)}
            $borderColor={statusBorderColor()}
            $textColor={statusTextColor()}
            $bgColor={statusBackgroundColor()}
          >
            {workPackage._links?.status?.title}
          </WorkPackageStatus>
        </WorkPackageDetails>
        <WorkPackageTitle>{title}</WorkPackageTitle>
      </WorkPackageCard>
    );
  }
);

WorkPackageElement.displayName = "WorkPackageElement";

const WorkPackageCard = styled.div.attrs({ className: "op-bn-work-package" })<{
  $inDropdown: boolean;
}>`
  ${defaultVariables}
  padding: var(--spacer-m) var(--spacer-l);
  background-color: var(--highlight-wp-background);
  border-radius: var(--bn-border-radius-small);

  ${({ $inDropdown }) =>
    $inDropdown &&
    `
    padding: var(--spacer-s) 0;
    background-color: transparent;
  `}
`;

const WorkPackageDetails = styled.div.attrs({
  className: 'op-bn-work-package--details'
})`
  display: flex;
  flex-wrap: wrap;
  gap: 0 10px;
  width: 100%;
  font-size: 0.86em;
`;

export const WorkPackageType = styled.div.attrs({
  className: 'op-bn-work-package--type'
})<{ $color: string; $compact?: boolean }>`
  ${({ $color }) => defaultColorStyles($color)}
  font-weight: ${({ $compact }) => ($compact ? 600 : 500)};
  text-transform: uppercase;
  color: ${typeTextColor} !important;
  ${({ $compact }) =>
    $compact &&
    `
    font-size: 12px;
    flex-shrink: 0;
  `}
`;

export const WorkPackageId = styled.div.attrs({
  className: 'op-bn-work-package--id'
})<{ $compact?: boolean }>`
  color: var(--bn-colors-highlights-gray-text);
  ${({ $compact }) =>
    $compact &&
    `
    font-size: 12px;
    font-weight: 400;
    flex-shrink: 0;
  `}
`;

export const WorkPackageStatus = styled.div.attrs({
  className: 'op-bn-work-package--status'
})<{ $baseColor: string; $borderColor?: string; $textColor?: string; $bgColor?: string; $compact?: boolean }>`
  ${({ $baseColor }) => defaultColorStyles($baseColor)}
  font-size: 0.95em;
  border-radius: 100px;
  border: 1px solid ${({ $borderColor }) => $borderColor ?? 'transparent'};
  padding: 0 7px;
  align-content: center;
  color: ${({ $textColor }) => $textColor} !important;
  background-color: ${({ $bgColor }) => $bgColor};
  ${({ $compact }) =>
    $compact &&
    `
    font-size: 12px;
    font-weight: 600;
    color: var(--bn-colors-editor-text) !important;
    flex-shrink: 0;
    line-height: 1.4;
    display: inline-flex;
    align-items: center;
    gap: 4px;
    border: 1px solid var(--op-status-border-color);
  `}
`;

export const WorkPackageTitle = styled.div.attrs({
  className: 'op-bn-work-package--title'
})<{ $compact?: boolean }>`
  flex-basis: max-content;
  color: var(--bn-colors-editor-text);
  font-weight: 500;
  ${({ $compact }) =>
    $compact &&
    `
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
    `
    font-size: 14px;
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  `}
`;
