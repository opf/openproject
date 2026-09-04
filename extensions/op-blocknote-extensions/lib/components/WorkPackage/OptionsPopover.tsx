import { useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { linkToWorkPackage } from '../../services/openProjectApi';
import type { InlineWpSize, BlockWpSize } from './types';
import styled from 'styled-components';
import { defaultWpVariables, menuSurfaceStyles } from './atoms';
import { useAnchoredPopover, PopoverPortal } from './anchoredPopover';
import { SizeMenu } from './SizeMenu';
import { FLOATING_Z_INDEX } from '../../utils/zIndex';
import {
  LinkExternalIcon,
  TrashIcon,
  ChevronDownIcon,
} from '@primer/octicons-react';
import {formatWorkPackageId} from '../../utils/id';

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

const Popover = styled.div.attrs({
  className: 'op-bn-inline-options',
  'data-testid': 'popover-content',
})`
  ${defaultWpVariables}
  position: absolute;
  z-index: ${FLOATING_Z_INDEX.options};
  ${menuSurfaceStyles}
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  display: flex;
  align-items: center;
  gap: 2px;
  bottom: calc(100% + 6px);
  left: 0;
  white-space: nowrap;
`;

const PopBtn = styled.button<{ $danger?:boolean }>`
  background: none;
  border: none;
  border-radius: var(--bn-border-radius-small);
  padding: var(--spacer-s) var(--spacer-m);
  cursor: pointer;
  font-size: 0.82em;
  color: ${({ $danger }) =>
    $danger
      ? 'var(--mantine-color-red-8)'
      : 'var(--bn-colors-editor-text, #333)'};
  display: flex;
  align-items: center;
  gap: var(--spacer-s);
  line-height: 1;
  &:hover {
    background-color: var(
      --bn-colors-highlights-gray-background,
      #f5f5f5
    );
  }
  svg { flex-shrink: 0; }
`;

const Divider = styled.div`
  width: 1px;
  height: 18px;
  background: var(--mantine-color-default-border);
  margin: 0 2px;
`;

const SizeButtonWrapper = styled.div`
  position: relative;
`;

const IcOpen = () => <LinkExternalIcon size={13} />;
const IcDelete = () => <TrashIcon size={13} />;
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

  const popoverRef = useRef<HTMLDivElement | null>(null);
  useAnchoredPopover({ anchorEl, popoverRef, placement: 'above' });

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

  const content = (
    // stopPropagation stops the outside-tap handlers from closing the popover.
    // Do NOT add preventDefault: on iOS it suppresses the first tap's click, so
    // every button then needs a priming tap.
    <Popover ref={popoverRef} onMouseDown={(e) => e.stopPropagation()}>
      {openId && (
        <>
          <PopBtn
            title={t('options.openInNewTab')}
            aria-label={t('options.openAriaLabel', { id: formatWorkPackageId(openId) })}
            onClick={(e) => {
              e.stopPropagation();
              window.open(linkToWorkPackage(openId), '_blank', 'noopener,noreferrer');
            }}
          >
            <IcOpen /> {t('options.open')}
          </PopBtn>

          <Divider />
        </>
      )}

      <SizeButtonWrapper>
        <PopBtn
          ref={setSizeButtonEl}
          title={t('options.changeSize')}
          aria-label={t('options.changeSize')}
          onClick={(e) => {
            e.stopPropagation();
            setShowSizes((prev) => !prev);
          }}
        >
          {displayedSize}
          <IcChevron />
        </PopBtn>

        {showSizes && (
          <SizeMenu
            anchorEl={sizeButtonEl}
            activeSize={displayedSizeKey}
            onPickInlineSize={pickInlineSize}
            onPickBlockSize={pickBlockSize}
          />
        )}
      </SizeButtonWrapper>

      <Divider />

      <PopBtn
        $danger
        title={t('options.remove')}
        data-testid="remove-btn"
        aria-label={t('options.removeAriaLabel')}
        onClick={(e) => {
          e.stopPropagation();
          onRemove?.();
          onClose();
        }}
      >
        <IcDelete /> {t('options.remove')}
      </PopBtn>
    </Popover>
  );

  return <PopoverPortal anchorEl={anchorEl}>{content}</PopoverPortal>;
};
