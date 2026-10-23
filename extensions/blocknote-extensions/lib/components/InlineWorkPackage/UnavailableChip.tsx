import type { ReactNode } from 'react';
import styled from 'styled-components';
import { useTranslation } from 'react-i18next';
import { EyeClosedIcon, AlertIcon } from '@primer/octicons-react';
import { ChipBase, ChipBaseXXS, InlineChip } from './chipLayouts';
import { WorkPackageId, WorkPackageTitleLink, workPackageLinkProps } from '../WorkPackage/atoms';
import { WpPreviewPopover } from '../WorkPackage/PreviewPopover';
import { UnavailableCard } from '../WorkPackage/UnavailableCard';
import { formatWorkPackageId } from '../../utils/id';
import { PreviewIndicator } from './PreviewIndicator';
import { buttonActivationProps } from '../../utils/a11y';
import type { TapActivationProps } from '../../utils/tapActivation';
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
  onActivation:TapActivationProps;
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
  onActivation,
  optionsPopover,
}:UnavailableChipProps) => {
  const { t } = useTranslation();
  const { previewOpen, triggerProps, indicatorProps, cardProps } = preview;

  const shortLabel = t(`unavailableWorkPackage.${kind}.short_message`);
  const inlineIcon = kind === 'unauthorized'
    ? <EyeClosedIcon size={12} verticalAlign="middle" />
    : <AlertIcon size={12} verticalAlign="middle" />;
  const cardIcon = kind === 'unauthorized'
    ? <EyeClosedIcon size={16} />
    : <AlertIcon size={16} />;

  const linked = kind === 'unauthorized';

  // xxs stays tiny (icon only); the full message lives in the preview.
  const iconOnly = size === 'xxs';
  const Base = iconOnly ? ChipBaseXXS : ChipBase;
  const showPreview = iconOnly && previewOpen;
  const hasIndicator = indicatorProps !== undefined;

  return (
    <InlineChip
      ref={setRef}
      data-drag-handle
      // icon-only xxs is a labelled state graphic; larger sizes carry visible text
      role={iconOnly && !hasIndicator ? 'img' : undefined}
      selected={selected}
      aria-label={iconOnly && !hasIndicator ? shortLabel : undefined}
      {...triggerProps}
      {...onActivation}
    >
      <Base>
        {hasIndicator ? <span {...buttonActivationProps(shortLabel)}>{inlineIcon}</span> : inlineIcon}
        {!iconOnly && <WorkPackageId as="span" $compact>{formatWorkPackageId(displayId)}</WorkPackageId>}
        {!iconOnly && (
          <UnavailableLabel>
            {linked
              ? <WorkPackageTitleLink {...workPackageLinkProps(displayId)}>{shortLabel}</WorkPackageTitleLink>
              : shortLabel}
          </UnavailableLabel>
        )}
        <PreviewIndicator preview={preview} displayId={displayId} />
      </Base>

      {showPreview && (
        <WpPreviewPopover
          anchorEl={anchorEl}
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
