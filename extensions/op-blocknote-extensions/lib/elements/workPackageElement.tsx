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

export const WorkPackageElement = ({ workPackage, inDropdown, linkTitle }: {workPackage: WorkPackage, inDropdown?: string, linkTitle?: boolean}) => {
  let title;
  if (linkTitle ?? false) {
    title = (
      <a
        href={linkToWorkPackage(workPackage.id)}
        onClick={(event) => {
          event.preventDefault();
          event.stopPropagation();
          window.open(linkToWorkPackage(workPackage.id), "_blank", "noopener,noreferrer");
        }}
      >
        {workPackage.subject}
      </a>
    );
  } else {
    title = workPackage.subject;
  }

  return (
    <WorkPackage in_dropdown={inDropdown ?? "false"}>
      <WorkPackageDetails>
        <WorkPackageType color={typeColor(workPackage)}>{workPackage._links?.type?.title}</WorkPackageType>
        <WorkPackageId>#{workPackage.id}</WorkPackageId>
        <WorkPackageStatus base_color={statusColor(workPackage)}>
          {workPackage._links?.status?.title}
        </WorkPackageStatus>
      </WorkPackageDetails>
      <WorkPackageTitle>{title}</WorkPackageTitle>
    </WorkPackage>
  )
}

const WorkPackage = styled.div.attrs({
  className: 'op-bn-work-package'
})<{ in_dropdown?: string }>`
  ${defaultVariables}
  padding: var(--spacer-m) var(--spacer-l);
  background-color: var(--highlight-wp-background);
  border-radius: var(--bn-border-radius-small);
  ${({ in_dropdown }) => in_dropdown && JSON.parse(in_dropdown) && `
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

const WorkPackageType = styled.div.attrs({
  className: 'op-bn-work-package--type'
})<{ color: string }>`
  ${({ color }) => defaultColorStyles(color)}
  font-weight: 500;
  text-transform: uppercase;
  color: ${() => typeTextColor} !important;
`;

const WorkPackageId = styled.div.attrs({
  className: 'op-bn-work-package--id'
})`
  color: var(--bn-colors-highlights-gray-text);
`;

const WorkPackageStatus = styled.div.attrs({
  className: 'op-bn-work-package--status'
})<{ base_color: string }>`
  ${({ base_color }) => defaultColorStyles(base_color)}
  font-size: 0.95em;
  border-radius: 100px;
  border: 1px solid ${() => statusBorderColor()};
  padding: 0 7px;
  align-content: center;
  color: ${() => statusTextColor()} !important;
  background-color: ${() => statusBackgroundColor()};
`;

const WorkPackageTitle = styled.div.attrs({
  className: 'op-bn-work-package--title'
})`
  flex-basis: max-content;
  color: var(--bn-colors-editor-text);
  font-weight: 500;
    
  a {
    cursor: pointer;
    text-decoration: none;
    color: var(--bn-colors-highlights-blue-text);

    &:hover {
        text-decoration: underline;
    }
  }
`;
