import styled from "styled-components";
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

const DESCRIPTION_MAX_CHARS = 300;

export interface BlockCardSharedProps {
  workPackage: WorkPackage;
  inDropdown?: boolean;
  linkTitle?: boolean;
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
}

function buildTitle(workPackage: WorkPackage, linkTitle: boolean) {
  const href = linkToWorkPackage(workPackage.id);
  if (!linkTitle) return workPackage.subject;
  return (
    <WorkPackageTitleLink
      href={href}
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        window.open(href, "_blank", "noopener,noreferrer");
      }}
    >
      {workPackage.subject}
    </WorkPackageTitleLink>
  );
}

const CardBase = styled.div<{ $inDropdown: boolean }>`
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

const CardDetails = styled.div.attrs({
  className: "op-bn-work-package--details",
})`
  display: flex;
  flex-wrap: wrap;
  gap: 0 10px;
  width: 100%;
  font-size: 0.86em;
`;

const CardDetailsSpaced = styled(CardDetails)`
  margin-bottom: var(--spacer-s);
`;

const MetaItem = styled.span`
  color: var(--bn-colors-highlights-gray-text);
  font-size: 0.9em;
`;

// Description snippet used in XL — clamped to 3 lines via CSS.
const DescriptionSnippet = styled.p`
  margin: var(--spacer-s) 0 0;
  padding: 0;
  font-size: 0.85em;
  color: var(--bn-colors-highlights-gray-text);
  line-height: 1.5;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
`;

// M — Compact card: Type, ID, Status + Subject
export const BlockCardM = ({
  workPackage,
  inDropdown = false,
  linkTitle = false,
  onClick,
  cardRef,
}: BlockCardSharedProps & { cardRef?: React.Ref<HTMLDivElement> }) => (
  <CardBase
    ref={cardRef}
    className="op-bn-work-package op-bn-work-package--m"
    $inDropdown={inDropdown}
    onClick={onClick}
    style={onClick ? { cursor: "pointer" } : undefined}
  >
    <CardDetails>
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
    </CardDetails>
    <WorkPackageTitle>{buildTitle(workPackage, linkTitle)}</WorkPackageTitle>
  </CardBase>
);


// L — Regular card: Type, ID, Status, Parent, Project + Subject
export const BlockCardL = ({
  workPackage,
  inDropdown = false,
  linkTitle = false,
  onClick,
  cardRef,
}: BlockCardSharedProps & { cardRef?: React.Ref<HTMLDivElement> }) => (
  <CardBase
    ref={cardRef}
    className="op-bn-work-package op-bn-work-package--l"
    $inDropdown={inDropdown}
    onClick={onClick}
    style={onClick ? { cursor: "pointer" } : undefined}
  >
    <CardDetailsSpaced>
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
      {workPackage._links?.parent?.title && (
        <MetaItem>↑ {workPackage._links.parent.title}</MetaItem>
      )}
      {workPackage._links?.project?.title && (
        <MetaItem>◈ {workPackage._links.project.title}</MetaItem>
      )}
    </CardDetailsSpaced>
    <WorkPackageTitle>{buildTitle(workPackage, linkTitle)}</WorkPackageTitle>
  </CardBase>
);

// XL — Full card: Type, ID, Status, Parent, Project + Subject + Description
export const BlockCardXL = ({
  workPackage,
  inDropdown = false,
  linkTitle = false,
  onClick,
  cardRef,
}: BlockCardSharedProps & { cardRef?: React.Ref<HTMLDivElement> }) => {
  const rawDescription = workPackage.description?.raw;
  const snippetText = rawDescription
    ? rawDescription.slice(0, DESCRIPTION_MAX_CHARS)
    : undefined;
  const isTruncated = rawDescription
    ? rawDescription.length > DESCRIPTION_MAX_CHARS
    : false;

  return (
    <CardBase
      ref={cardRef}
      className="op-bn-work-package op-bn-work-package--xl"
      $inDropdown={inDropdown}
      onClick={onClick}
      style={onClick ? { cursor: "pointer" } : undefined}
    >
      <CardDetailsSpaced>
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
        {workPackage._links?.parent?.title && (
          <MetaItem>↑ {workPackage._links.parent.title}</MetaItem>
        )}
        {workPackage._links?.project?.title && (
          <MetaItem>◈ {workPackage._links.project.title}</MetaItem>
        )}
      </CardDetailsSpaced>
      <WorkPackageTitle>{buildTitle(workPackage, linkTitle)}</WorkPackageTitle>
      {snippetText && (
        <DescriptionSnippet>
          {snippetText}
          {isTruncated && "…"}
        </DescriptionSnippet>
      )}
    </CardBase>
  );
};