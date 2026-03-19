import React from "react";
import type { WorkPackage } from "../../openProjectTypes";
import { linkToWorkPackage } from "../../services/openProjectApi";
import {
  ChipBaseXXS,
  ChipBaseXS,
  ChipBaseS,
  IdAtom,
  TypeAtom,
  SubjectLink,
  StatusPill,
  StatusChevron,
} from "./atoms";

// Shared props for the title link DRY helper so each chip doesn't repeat them
const subjectLinkProps = (wp: WorkPackage) => ({
  href: linkToWorkPackage(wp.id),
  target: "_blank" as const,
  rel: "noopener noreferrer",
  // Prevent click from bubbling up to the chip's onClick (options popover)
  onClick: (e: React.MouseEvent) => e.stopPropagation(),
});

// XXS — "#ID  [Title]"  (padding 2px 8px) 
export const WpChipXXS = ({ wp }: { wp: WorkPackage }) => (
  <ChipBaseXXS>
    <IdAtom>#{wp.id}</IdAtom>
    <SubjectLink {...subjectLinkProps(wp)}>{wp.subject}</SubjectLink>
  </ChipBaseXXS>
);

// XS — "#ID  TYPE  [Title]"  (padding 8px) 
export const WpChipXS = ({ wp }: { wp: WorkPackage }) => (
  <ChipBaseXS>
    <IdAtom>#{wp.id}</IdAtom>
    {wp._links?.type?.title && <TypeAtom>{wp._links.type.title}</TypeAtom>}
    <SubjectLink {...subjectLinkProps(wp)}>{wp.subject}</SubjectLink>
  </ChipBaseXS>
);

// S — "#ID  TYPE  [New]  [Title]"  (padding 8px) 
export const WpChipS = ({ wp }: { wp: WorkPackage }) => (
  <ChipBaseS>
    <IdAtom>#{wp.id}</IdAtom>
    {wp._links?.type?.title   && <TypeAtom>{wp._links.type.title}</TypeAtom>}
    {wp._links?.status?.title && (
      <StatusPill>
        {wp._links.status.title}
        <StatusChevron />
      </StatusPill>
    )}
    <SubjectLink {...subjectLinkProps(wp)}>{wp.subject}</SubjectLink>
  </ChipBaseS>
);