import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { linkToWorkPackage } from '../../services/openProjectApi';
import type { InlineWpSize, BlockWpSize } from './types';
import styled from 'styled-components';
import { SizeMenu } from './SizeMenu';
import { ChevronDownIcon } from '@primer/octicons-react';
import {formatWorkPackageId} from '../../utils/id';
import { useTapActivation } from '../../utils/tapActivation';
import { OptionsButton, OptionsPopover } from '../shared/OptionsPopover';

export interface WpOptionsProps {
  wp?:WorkPackage;
  displayId?:string;
  currentSize?:InlineWpSize;
  currentBlockSize?:BlockWpSize;
  anchorEl?:HTMLElement | null;
  onClose:() => void;
  onResize?:(size:InlineWpSize) => void;
  onRemove?:() => void;
  onConvertToBlock?:(size:BlockWpSize) => void;
  onConvertToInline?:(size:InlineWpSize) => void;
  onResizeBlock?:(size:BlockWpSize) => void;
}

const SizeButtonWrapper = styled.div`
  position: relative;
`;

const IcChevron = () => <ChevronDownIcon size={10} />;

export const WpOptionsPopover = ({
  wp,
  displayId,
  currentSize,
  currentBlockSize,
  anchorEl,
  onClose,
  onResize,
  onRemove,
  onConvertToBlock,
  onConvertToInline,
  onResizeBlock,
}:WpOptionsProps) => {
  const { t } = useTranslation();
  const [showSizes, setShowSizes] = useState(false);

  const tapProps = useTapActivation();

  const [sizeButtonEl, setSizeButtonEl] = useState<HTMLButtonElement | null>(null);

  const isBlock = currentSize === undefined;

  const openId = wp?.displayId ?? displayId;

  const displayedSizeKey = isBlock ? (currentBlockSize ?? 'm') : currentSize;
  const displayedSize = t(`sizes.${displayedSizeKey}.label`);

  const closeMenu = () => {
    setShowSizes(false);
    onClose();
  };

  const pickInlineSize = (size:InlineWpSize) => {
    if (isBlock) {
      onConvertToInline?.(size);
    } else {
      onResize?.(size);
    }
    closeMenu();
  };

  const pickBlockSize = (size:BlockWpSize) => {
    if (isBlock) {
      onResizeBlock?.(size);
    } else {
      onConvertToBlock?.(size);
    }
    closeMenu();
  };

  return (
    <OptionsPopover
      anchorEl={anchorEl}
      openHref={openId ? linkToWorkPackage(openId) : undefined}
      openAriaLabel={openId ? t('options.openAriaLabel', { id: formatWorkPackageId(openId) }) : undefined}
      removeAriaLabel={t('options.removeAriaLabel')}
      onRemove={onRemove}
      onClose={onClose}
    >
      <SizeButtonWrapper>
        <OptionsButton
          ref={setSizeButtonEl}
          title={t('options.changeSize')}
          aria-label={t('options.changeSize')}
          {...tapProps((event) => {
            event?.stopPropagation();
            setShowSizes((prev) => !prev);
          })}
        >
          {displayedSize}
          <IcChevron />
        </OptionsButton>

        {showSizes && (
          <SizeMenu
            anchorEl={sizeButtonEl}
            activeSize={displayedSizeKey}
            onPickInlineSize={pickInlineSize}
            onPickBlockSize={pickBlockSize}
          />
        )}
      </SizeButtonWrapper>
    </OptionsPopover>
  );
};
