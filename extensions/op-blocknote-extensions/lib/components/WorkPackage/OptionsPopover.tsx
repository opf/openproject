import { useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import type { WorkPackage } from '../../openProjectTypes';
import { linkToWorkPackage } from '../../services/openProjectApi';
import type { InlineWpSize, BlockWpSize } from './types';
import styled from 'styled-components';
import { defaultWpVariables } from './atoms';
import { useAnchoredPopover, PopoverPortal } from './anchoredPopover';
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

const INLINE_SIZE_OPTIONS:InlineWpSize[] = ['xxs', 'xs', 's'];
const BLOCK_SIZE_OPTIONS:BlockWpSize[] = ['m'];

const Popover = styled.div.attrs({
  className: 'op-bn-inline-options',
  'data-testid': 'popover-content',
})`
  ${defaultWpVariables}
  position: absolute;
  z-index: ${FLOATING_Z_INDEX.options};
  background-color: var(--bn-colors-menu-background, #fff);
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

const SizeMenu = styled.div.attrs<{
  'data-testid'?:string;
}>({
  'data-testid': 'size-menu',
})`
  position: absolute;
  top: calc(100% + var(--spacer-s));
  left: 0;
  z-index: 1;
  background: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 200px;
`;

const SizeMenuLabel = styled.div`
  padding: var(--spacer-s) var(--spacer-m);
  font-size: 0.75em;
  opacity: 0.5;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const SizeMenuDivider = styled.div`
  height: 1px;
  background: var(--mantine-color-default-border);
  margin: var(--spacer-s) 0;
`;

const SizeBtn = styled.button<{ $active?:boolean }>`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  width: 100%;
  background: ${({ $active }) =>
    $active
      ? 'var(--bn-colors-highlights-gray-background, #f0f0f0)'
      : 'none'};
  border: none;
  border-radius: var(--bn-border-radius-small);
  padding: var(--spacer-s) var(--spacer-m);
  cursor: pointer;
  font-size: 0.82em;
  color: var(--bn-colors-editor-text, #333);
  text-align: left;
  &:hover { background: var(--bn-colors-highlights-gray-background, #f0f0f0); }
`;

const SizeBtnLabel = styled.strong`
  min-width: 28px;
`;

const SizeBtnDesc = styled.span`
  opacity: 0.6;
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

  const isBlock = currentSize === undefined;

  const openId = wp?.displayId ?? displayId;

  const displayedSizeKey = isBlock ? (currentBlockSize ?? 'm') : currentSize;
  const displayedSize = t(`sizes.${displayedSizeKey}.label`);

  const closeMenu = () => {
    setShowSizes(false);
    onClose();
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
          <SizeMenu>
            <SizeMenuLabel>{t('options.inlineSizeLabel')}</SizeMenuLabel>
            {INLINE_SIZE_OPTIONS.map((size) => {
              return (
                <SizeBtn
                  key={size}
                  aria-label={t(`sizes.${size}.label`)}
                  $active={!isBlock && currentSize === size}
                  onMouseDown={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    if (isBlock) {
                      onConvertToInline?.(size);
                    } else {
                      onResize?.(size);
                    }
                    closeMenu();
                  }}
                >
                  <SizeBtnLabel>{t(`sizes.${size}.label`)}</SizeBtnLabel>
                  <SizeBtnDesc>{t(`sizes.${size}.desc`)}</SizeBtnDesc>
                </SizeBtn>
              );
            })}

            <SizeMenuDivider />

            <SizeMenuLabel>{t('options.blockSizeLabel')}</SizeMenuLabel>
            {BLOCK_SIZE_OPTIONS.map((size) => {
              return (
                <SizeBtn
                  key={size}
                  aria-label={t(`sizes.${size}.label`)}
                  $active={isBlock && currentBlockSize === size}
                  onMouseDown={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    if (isBlock) {
                      onResizeBlock?.(size);
                    } else {
                      onConvertToBlock?.(size);
                    }
                    closeMenu();
                  }}
                >
                  <SizeBtnLabel>{t(`sizes.${size}.label`)}</SizeBtnLabel>
                  <SizeBtnDesc>{t(`sizes.${size}.desc`)}</SizeBtnDesc>
                </SizeBtn>
              );
            })}
          </SizeMenu>
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
