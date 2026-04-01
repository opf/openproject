import styled from "styled-components";
import { forwardRef } from "react";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import {
  defaultWpVariables,
  WorkPackageId,
  WorkPackageType,
  WorkPackageStatus,
  WorkPackageTitle,
  WorkPackageTitleLink,
} from "../WorkPackage/atoms";
import {
  typeColor,
  statusColor,
  statusBorderColor,
  statusTextColor,
  statusBackgroundColor,
} from "../../services/colors";

interface BlockCardProps {
  workPackage: WorkPackage;
  inDropdown?: boolean;
  linkTitle?: boolean;
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
}

export const BlockCard = forwardRef<HTMLDivElement, BlockCardProps>(
  ({ workPackage, inDropdown = false, linkTitle = false, onClick }, ref) => {
    const href = linkToWorkPackage(workPackage.id);

    const title = linkTitle ? (
      <WorkPackageTitleLink
        href={href}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
          window.open(href, "_blank", "noopener,noreferrer");
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

BlockCard.displayName = "BlockCard";

const WorkPackageCard = styled.div.attrs({ className: "op-bn-work-package" })<{
  $inDropdown: boolean;
}>`
  ${defaultWpVariables}
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
  className: "op-bn-work-package--details",
})`
  display: flex;
  flex-wrap: wrap;
  gap: 0 10px;
  width: 100%;
  font-size: 0.86em;
`;