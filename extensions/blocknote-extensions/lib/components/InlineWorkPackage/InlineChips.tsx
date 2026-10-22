import type { WorkPackage } from '../../openProjectTypes';
import {
  typeColor,
  statusColor,
  statusBorderColor,
  statusTextColor,
  statusBackgroundColor,
} from '../../services/colors';
import { ChipBaseXXS, ChipBaseXS, ChipBaseS } from './chipLayouts';
import {
  WorkPackageId,
  WorkPackageType,
  WorkPackageStatus,
  WorkPackageTitleLink,
  workPackageLinkProps,
  WRAP_OPPORTUNITY,
} from '../WorkPackage/atoms';
import { formatWorkPackageId } from '../../utils/id';
import { PreviewIndicator } from './PreviewIndicator';
import { buttonActivationProps } from '../../utils/a11y';
import type { WorkPackagePreview } from '../../hooks/useWorkPackagePreview';

const resolvedDisplayId = (wp:WorkPackage) => wp.displayId ?? String(wp.id);

const titleLinkProps = (wp:WorkPackage) => ({
  as: 'a' as const,
  ...workPackageLinkProps(resolvedDisplayId(wp)),
  $compact: true,
});

// XXS — "#ID"
export const WpChipXXS = ({ wp, preview, actionLabel }:{
  wp:WorkPackage;
  preview:WorkPackagePreview;
  actionLabel:string;
}) => (
  <ChipBaseXXS>
    <WorkPackageId
      as="span"
      $compact
      {...(preview.indicatorProps ? buttonActivationProps(actionLabel) : {})}
    >
      {formatWorkPackageId(resolvedDisplayId(wp))}
    </WorkPackageId>
    <PreviewIndicator preview={preview} displayId={resolvedDisplayId(wp)} />
  </ChipBaseXXS>
);

// XS — "#ID TYPE subject"
export const WpChipXS = ({ wp }:{ wp:WorkPackage }) => (
  <ChipBaseXS>
    <WorkPackageId as="span" $compact>{formatWorkPackageId(resolvedDisplayId(wp))}</WorkPackageId>
    {WRAP_OPPORTUNITY}
    {wp._links?.type?.title && (
      <WorkPackageType as="span" $compact $color={typeColor(wp)}>
        {wp._links.type.title}
      </WorkPackageType>
    )}
    {WRAP_OPPORTUNITY}
    <WorkPackageTitleLink {...titleLinkProps(wp)}>
      {wp.subject}
    </WorkPackageTitleLink>
  </ChipBaseXS>
);

// S — "#ID TYPE [Status] subject"
export const WpChipS = ({ wp }:{ wp:WorkPackage }) => (
  <ChipBaseS>
    <WorkPackageId as="span" $compact>{formatWorkPackageId(resolvedDisplayId(wp))}</WorkPackageId>
    {WRAP_OPPORTUNITY}
    {wp._links?.type?.title && (
      <WorkPackageType as="span" $compact $color={typeColor(wp)}>
        {wp._links.type.title}
      </WorkPackageType>
    )}
    {WRAP_OPPORTUNITY}
    {wp._links?.status?.title && (
      <WorkPackageStatus
        as="span"
        $baseColor={statusColor(wp)}
        $borderColor={statusBorderColor()}
        $textColor={statusTextColor()}
        $bgColor={statusBackgroundColor()}
      >
        {wp._links.status.title}
      </WorkPackageStatus>
    )}
    {WRAP_OPPORTUNITY}
    <WorkPackageTitleLink {...titleLinkProps(wp)}>
      {wp.subject}
    </WorkPackageTitleLink>
  </ChipBaseS>
);