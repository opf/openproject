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
import { menuButtonProps } from '../../utils/a11y';
import { describeUnavailableWorkPackage, workPackageLabel, type UnavailableKind } from '../WorkPackage/description';
import type { TapActivationProps } from '../../utils/tapActivation';
import type { InlineWpSize } from '../WorkPackage/types';
import type { WorkPackagePreview } from '../../hooks/useWorkPackagePreview';

export interface UnavailableChipProps {
  kind:UnavailableKind;
  size:InlineWpSize;
  displayId:string;
  setRef:(node:HTMLElement | null) => void;
  anchorEl:HTMLElement | null;
  selected:boolean;
  optionsOpen:boolean;
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
  optionsOpen,
  preview,
  onActivation,
  optionsPopover,
}:UnavailableChipProps) => {
  const { t } = useTranslation();
  const { previewOpen, triggerProps, cardProps } = preview;

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
  // Icon-only, the icon stands in for the identifier as what opens the options.
  const menuButton = menuButtonProps(
    iconOnly ? describeUnavailableWorkPackage(t, displayId, kind) : workPackageLabel(t, displayId),
    optionsOpen,
  );

  return (
    <InlineChip
      ref={setRef}
      data-drag-handle
      selected={selected}
      {...triggerProps}
      {...onActivation}
    >
      <Base>
        {iconOnly ? <span {...menuButton}>{inlineIcon}</span> : inlineIcon}
        {!iconOnly && <WorkPackageId as="span" $compact {...menuButton}>{formatWorkPackageId(displayId)}</WorkPackageId>}
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
