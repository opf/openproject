import styled from 'styled-components';
import type { WorkPackage } from '../../openProjectTypes';
import { linkToWorkPackage } from '../../services/openProjectApi';
import {
  defaultWpVariables,
  WorkPackageId,
  WorkPackageType,
  WorkPackageStatus,
  WorkPackageTitle,
  WorkPackageTitleLink,
  WRAP_OPPORTUNITY,
} from '../WorkPackage/atoms';
import {
  typeColor,
  statusColor,
  statusBorderColor,
  statusTextColor,
  statusBackgroundColor,
} from '../../services/colors';
import { formatWorkPackageId } from '../../utils/id';

const DESCRIPTION_MAX_CHARS = 300;

/* keeps the ↑ / ◈ marker on the same line as the label it marks  */
const MARKER_GAP = '\u00A0';

export interface BlockCardSharedProps {
  workPackage:WorkPackage;
  inDropdown?:boolean;
  linkTitle?:boolean;
  onClick?:(e:React.MouseEvent<HTMLDivElement>) => void;
}

function buildTitle(workPackage:WorkPackage, linkTitle:boolean) {
  const href = linkToWorkPackage(workPackage.displayId);
  if (!linkTitle) return workPackage.subject;
  return (
    <WorkPackageTitleLink
      href={href}
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        window.open(href, '_blank', 'noopener,noreferrer');
      }}
    >
      {workPackage.subject}
    </WorkPackageTitleLink>
  );
}

const CardBase = styled.div<{ $inDropdown:boolean }>`
  ${defaultWpVariables}
  padding: var(--spacer-m) var(--spacer-l);
  background-color: var(--highlight-wp-background);
  border-radius: var(--bn-border-radius);

  ${({ $inDropdown }) =>
    $inDropdown &&
    `
    padding: var(--spacer-s) 0;
    background-color: transparent;
  `}
`;

const CardDetails = styled.div.attrs({
  className: 'op-bn-work-package--details',
})`
  width: 100%;
  font-size: 0.86em;
  line-height: 1.5;

  & > *:not(:last-child) {
    margin-right: 10px;
  }
`;

const CardDetailsSpaced = styled(CardDetails)`
  margin-bottom: var(--spacer-s);
`;

const MetaItem = styled.span`
  color: var(--op-wp-meta-color) !important;
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

const CardMeta = ({
  workPackage,
  withRelations = false,
}:{ workPackage:WorkPackage; withRelations?:boolean }) => (
  <>
    <WorkPackageType $color={typeColor(workPackage)}>
      {workPackage._links?.type?.title}
    </WorkPackageType>
    {WRAP_OPPORTUNITY}
    <WorkPackageId>{formatWorkPackageId(workPackage.displayId)}</WorkPackageId>
    {WRAP_OPPORTUNITY}
    <WorkPackageStatus
      $baseColor={statusColor(workPackage)}
      $borderColor={statusBorderColor()}
      $textColor={statusTextColor()}
      $bgColor={statusBackgroundColor()}
    >
      {workPackage._links?.status?.title}
    </WorkPackageStatus>
    {withRelations && workPackage._links?.parent?.title && (
      <>
        {WRAP_OPPORTUNITY}
        <MetaItem>↑{MARKER_GAP}{workPackage._links.parent.title}</MetaItem>
      </>
    )}
    {withRelations && workPackage._links?.project?.title && (
      <>
        {WRAP_OPPORTUNITY}
        <MetaItem>◈{MARKER_GAP}{workPackage._links.project.title}</MetaItem>
      </>
    )}
  </>
);

// M — Compact card: Type, ID, Status + Subject
export const BlockCardM = ({
  workPackage,
  inDropdown = false,
  linkTitle = false,
  onClick,
  cardRef,
}:BlockCardSharedProps & { cardRef?:React.Ref<HTMLDivElement> }) => (
  <CardBase
    ref={cardRef}
    className="op-bn-work-package op-bn-work-package--m"
    $inDropdown={inDropdown}
    onClick={onClick}
    // role=button so iOS treats the card as interactive and fires the click on
    // the first tap (a plain div inside the contenteditable needs two). Interim:
    // mirrors the inline chip;
    role={onClick ? 'button' : undefined}
    data-testid="block-card"
    style={onClick ? { cursor: 'pointer' } : undefined}
  >
    <CardDetails>
      <CardMeta workPackage={workPackage} />
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
}:BlockCardSharedProps & { cardRef?:React.Ref<HTMLDivElement> }) => (
  <CardBase
    ref={cardRef}
    className="op-bn-work-package op-bn-work-package--l"
    $inDropdown={inDropdown}
    onClick={onClick}
    role={onClick ? 'button' : undefined}
    data-testid="block-card"
    style={onClick ? { cursor: 'pointer' } : undefined}
  >
    <CardDetailsSpaced>
      <CardMeta workPackage={workPackage} withRelations />
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
}:BlockCardSharedProps & { cardRef?:React.Ref<HTMLDivElement> }) => {
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
      role={onClick ? 'button' : undefined}
      data-testid="block-card"
      style={onClick ? { cursor: 'pointer' } : undefined}
    >
      <CardDetailsSpaced>
        <CardMeta workPackage={workPackage} withRelations />
      </CardDetailsSpaced>
      <WorkPackageTitle>{buildTitle(workPackage, linkTitle)}</WorkPackageTitle>
      {snippetText && (
        <DescriptionSnippet>
          {snippetText}
          {isTruncated && '…'}
        </DescriptionSnippet>
      )}
    </CardBase>
  );
};