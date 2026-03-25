import React from "react";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import {
  typeColor,
  statusColor,
  statusBorderColor,
  statusTextColor,
  statusBackgroundColor,
} from "../../services/colors";

import {
  ChipBaseXXS,
  ChipBaseXS,
  ChipBaseS,
  StatusChevron,
} from "./atoms";
import {
  WorkPackageId,
  WorkPackageType,
  WorkPackageStatus,
  WorkPackageTitleLink,
} from "../../elements/workPackageElement";

const titleLinkProps = (wp: WorkPackage) => ({
  as: "a" as const,
  href: linkToWorkPackage(wp.id),
  target: "_blank" as const,
  rel: "noopener noreferrer",
  $compact: true,
  // Prevent click from bubbling up to the chip's onClick (options popover)
  onClick: (e: React.MouseEvent) => e.stopPropagation(),
});

// XXS — "#ID  [Title]"  (padding 2px 8px) 
export const WpChipXXS = ({ wp }: { wp: WorkPackage }) => (
  <ChipBaseXXS>
    <WorkPackageId as="span" $compact>#{wp.id}</WorkPackageId>
  </ChipBaseXXS>
);

// XS — "#ID  TYPE  [Title]"  (padding 8px) 
export const WpChipXS = ({ wp }: { wp: WorkPackage }) => (
  <ChipBaseXS>
    <WorkPackageId as="span" $compact>#{wp.id}</WorkPackageId>
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

// S — "#ID  TYPE  [New]  [Title]"  (padding 8px) 
export const WpChipS = ({ wp }: { wp: WorkPackage }) => (
  <ChipBaseS>
    <WorkPackageId as="span" $compact>#{wp.id}</WorkPackageId>
    {wp._links?.type?.title && (
      <WorkPackageType as="span" $compact $color={typeColor(wp)}>
        {wp._links.type.title}
      </WorkPackageType>
    )}
    {wp._links?.status?.title && (
      <WorkPackageStatus
        as="span"
        $compact
        $baseColor={statusColor(wp)}
        $borderColor={statusBorderColor()}
        $textColor={statusTextColor()}
        $bgColor={statusBackgroundColor()}
      >
        {wp._links.status.title}
        <StatusChevron />
      </WorkPackageStatus>
    )}
    <WorkPackageTitleLink {...titleLinkProps(wp)}>
      {wp.subject}
    </WorkPackageTitleLink>
  </ChipBaseS>
);