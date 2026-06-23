import React from 'react';
import type { WorkPackage } from '../../openProjectTypes';
import { linkToWorkPackage } from '../../services/openProjectApi';
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
} from '../WorkPackage/atoms';
import { formatWorkPackageId } from '../../utils/id';

const resolvedDisplayId = (wp:WorkPackage) => wp.displayId ?? String(wp.id);

const titleLinkProps = (wp:WorkPackage) => ({
  as: 'a' as const,
  href: linkToWorkPackage(resolvedDisplayId(wp)),
  target: '_blank' as const,
  rel: 'noopener noreferrer',
  $compact: true,
  onClick: (e:React.MouseEvent) => e.stopPropagation(),
});

// XXS — "#ID"
export const WpChipXXS = ({ wp }:{ wp:WorkPackage }) => (
  <ChipBaseXXS>
    <WorkPackageId as="span" $compact>{formatWorkPackageId(resolvedDisplayId(wp))}</WorkPackageId>
  </ChipBaseXXS>
);

// XS — "#ID TYPE subject"
export const WpChipXS = ({ wp }:{ wp:WorkPackage }) => (
  <ChipBaseXS>
    <WorkPackageId as="span" $compact>{formatWorkPackageId(resolvedDisplayId(wp))}</WorkPackageId>
    {wp._links?.type?.title && (
      <WorkPackageType as="span" $compact $color={typeColor(wp)}>
        {wp._links.type.title}
      </WorkPackageType>
    )}
    <WorkPackageTitleLink {...titleLinkProps(wp)}>
      {wp.subject}
    </WorkPackageTitleLink>
  </ChipBaseXS>
);

// S — "#ID TYPE [Status] subject"
export const WpChipS = ({ wp }:{ wp:WorkPackage }) => (
  <ChipBaseS>
    <WorkPackageId as="span" $compact>{formatWorkPackageId(resolvedDisplayId(wp))}</WorkPackageId>
    {wp._links?.type?.title && (
      <WorkPackageType as="span" $compact $color={typeColor(wp)}>
        {wp._links.type.title}
      </WorkPackageType>
    )}
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
    <WorkPackageTitleLink {...titleLinkProps(wp)}>
      {wp.subject}
    </WorkPackageTitleLink>
  </ChipBaseS>
);