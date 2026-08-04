import type { ReactNode } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { EyeClosedIcon, AlertIcon } from '@primer/octicons-react';
import { ChipBase, ChipBaseXXS, InlineChip } from './chipLayouts';
import { WorkPackageId, WorkPackageTitleLink, workPackageLinkProps } from '../WorkPackage/atoms';
import { WpPreviewPopover } from '../WorkPackage/PreviewPopover';
import { UnavailableCard } from '../WorkPackage/UnavailableCard';
import { formatWorkPackageId } from '../../utils/id';
import type { InlineWpSize } from '../WorkPackage/types';
import type { WorkPackagePreview } from '../../hooks/useWorkPackagePreview';

export interface UnavailableChipProps {
  kind:'unauthorized' | 'error';
  size:InlineWpSize;
  displayId:string;
  setRef:(node:HTMLElement | null) => void;
  anchorEl:HTMLElement | null;
  selected:boolean;
  preview:WorkPackagePreview;
  onClick:(e:React.MouseEvent) => void;
  optionsPopover:ReactNode;
}

const UnavailableLabel = styled.span`
  color: var(--bn-colors-editor-text);
`;

export const UnavailableChip = ({
  kind,
  size,
  displayId,
  setRef,
  anchorEl,
  selected,
  preview,
  onClick,
  optionsPopover,
}:UnavailableChipProps) => {
  const { t } = useTranslation();
  const { previewOpen, closePreview, triggerProps, cardProps } = preview;

  const inlineIcon = kind === 'unauthorized'
    ? <EyeClosedIcon size={12} verticalAlign="middle" />
    : <AlertIcon size={12} verticalAlign="middle" />;
  const cardIcon = kind === 'unauthorized'
    ? <EyeClosedIcon size={16} />
    : <AlertIcon size={16} />;
  const shortLabel = t(`unavailableWorkPackage.${kind}.short_message`);

  const linked = kind === 'unauthorized';

  // xxs stays tiny (icon only); the full message lives in the hover/long-press preview.
  const iconOnly = size === 'xxs';
  const Base = iconOnly ? ChipBaseXXS : ChipBase;
  const showPreview = iconOnly && previewOpen;

  return (
    <InlineChip
      ref={setRef}
      data-drag-handle
      // icon-only xxs is a labelled state graphic; larger sizes carry visible text
      role={iconOnly ? 'img' : undefined}
      selected={selected}
      aria-label={iconOnly ? shortLabel : undefined}
      {...triggerProps}
      onClick={onClick}
    >
      <Base>
        {inlineIcon}
        {!iconOnly && <WorkPackageId as="span" $compact>{formatWorkPackageId(displayId)}</WorkPackageId>}
        {!iconOnly && (
          <UnavailableLabel>
            {linked
              ? <WorkPackageTitleLink {...workPackageLinkProps(displayId)}>{shortLabel}</WorkPackageTitleLink>
              : shortLabel}
          </UnavailableLabel>
        )}
      </Base>

      {showPreview && (
        <WpPreviewPopover
          anchorEl={anchorEl}
          onClose={closePreview}
          {...cardProps}
        >
          <UnavailableCard
            icon={cardIcon}
            headerKey={`unavailableWorkPackage.${kind}.header`}
            messageKey={`unavailableWorkPackage.${kind}.message`}
            displayId={displayId}
            linkHeader={linked}
          />
        </WpPreviewPopover>
      )}

      {optionsPopover}
    </InlineChip>
  );
};
