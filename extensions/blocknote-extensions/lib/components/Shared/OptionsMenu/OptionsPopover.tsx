import { useEffect, useEffectEvent, useId, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { linkToWorkPackage } from '../../../services/openProjectApi';
import styled from 'styled-components';
import { defaultWpVariables, menuItemFocusStyles, menuSurfaceStyles } from '../../WorkPackage/atoms';
import { useAnchoredPopover, PopoverPortal } from '../../WorkPackage/anchoredPopover';
import { SizeMenu } from './SizeMenu';
import type { SizeGroup } from './types';
import { FLOATING_Z_INDEX } from '../../../utils/zIndex';
import {
  LinkExternalIcon,
  TrashIcon,
  ChevronDownIcon,
} from '@primer/octicons-react';
import { formatWorkPackageId } from '../../../utils/id';
import { useTapActivation } from '../../../utils/tapActivation';
import { focusMenuItem, hasFocusWithin, isKeyboardClick, KEYBOARD_FOCUS, navigateMenu } from '../../../utils/a11y';

export interface OptionsPopoverProps {
  ariaLabel?:string;
  openId?:string;
  activeSize:string;
  sizeLabel:string;
  sizeGroups:SizeGroup[];
  removeAriaLabel:string;
  anchorEl?:HTMLElement | null;
  autoFocus?:boolean;
  onClose:() => void;
  onRestoreFocus?:() => void;
  onRemove?:() => void;
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
  &:hover,
  &:focus-visible {
    background-color: var(
      --bn-colors-highlights-gray-background,
      #f5f5f5
    );
  }
  ${menuItemFocusStyles}
  svg { flex-shrink: 0; }
`;

const Divider = styled.div.attrs({ role: 'separator', 'aria-orientation': 'vertical' as const })`
  width: 1px;
  height: 18px;
  background: var(--mantine-color-default-border);
  margin: 0 2px;
`;

const SizeButtonWrapper = styled.div`
  position: relative;
`;

const CLOSING_KEYS = ['Escape', 'Tab'];

const IcOpen = () => <LinkExternalIcon size={13} />;
const IcDelete = () => <TrashIcon size={13} />;
const IcChevron = () => <ChevronDownIcon size={10} />;

export const OptionsPopover = ({
  ariaLabel,
  openId,
  activeSize,
  sizeLabel,
  sizeGroups,
  removeAriaLabel,
  anchorEl,
  autoFocus = false,
  onClose,
  onRestoreFocus,
  onRemove,
}:OptionsPopoverProps) => {
  const { t } = useTranslation();
  const [showSizes, setShowSizes] = useState(false);
  const [sizesTakeFocus, setSizesTakeFocus] = useState(false);
  const sizeMenuId = useId();

  const tapProps = useTapActivation();
  const popoverRef = useRef<HTMLDivElement | null>(null);
  useAnchoredPopover({ anchorEl, popoverRef, placement: 'above' });

  const [sizeButtonEl, setSizeButtonEl] = useState<HTMLButtonElement | null>(null);

  const closeMenu = () => {
    const restoreFocus = hasFocusWithin(popoverRef.current);
    setShowSizes(false);
    onClose();
    if (restoreFocus) onRestoreFocus?.();
  };

  const closeFromEditor = useEffectEvent((event:KeyboardEvent) => {
    if (!CLOSING_KEYS.includes(event.key) || hasFocusWithin(popoverRef.current)) return;
    event.preventDefault();
    event.stopPropagation();
    closeMenu();
  });

  useEffect(() => {
    document.addEventListener('keydown', closeFromEditor, { capture: true });
    return () => document.removeEventListener('keydown', closeFromEditor, { capture: true });
  }, []);

  useEffect(() => {
    if (autoFocus) focusMenuItem(popoverRef.current, 'first');
  }, [autoFocus]);

  const closeSizes = () => {
    setShowSizes(false);
    sizeButtonEl?.focus(KEYBOARD_FOCUS);
  };

  const openSizesFromArrowKey = (event:React.KeyboardEvent<HTMLButtonElement>) => {
    if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp') return;
    event.preventDefault();
    event.stopPropagation();
    setSizesTakeFocus(true);
    setShowSizes(true);
  };

  const handleKeyDown = (event:React.KeyboardEvent<HTMLDivElement>) => {
    if (navigateMenu(event, 'horizontal')) return;
    if (!CLOSING_KEYS.includes(event.key)) return;
    event.preventDefault();
    closeMenu();
  };

  const groupsClosingOnPick = sizeGroups.map((group) => ({
    ...group,
    options: group.options.map((option) => ({
      ...option,
      pick: () => {
        option.pick();
        closeMenu();
      },
    })),
  }));

  const content = (
    // stopPropagation stops the outside-tap handlers from closing the popover.
    // Do NOT add preventDefault: on iOS it suppresses the first tap's click, so
    // every button then needs a priming tap.
    <Popover
      ref={popoverRef}
      role="menu"
      aria-orientation="horizontal"
      aria-label={ariaLabel}
      onKeyDown={handleKeyDown}
      onMouseDown={(e) => e.stopPropagation()}
      onTouchStart={(e) => e.stopPropagation()}
    >
      {openId && (
        <>
          <PopBtn
            role="menuitem"
            tabIndex={-1}
            title={t('options.openInNewTab')}
            aria-label={t('options.openAriaLabel', { id: formatWorkPackageId(openId) })}
            {...tapProps((event) => {
              event?.stopPropagation();
              window.open(linkToWorkPackage(openId), '_blank', 'noopener,noreferrer');
            })}
          >
            <IcOpen /> {t('options.openWorkPackage', { id: formatWorkPackageId(openId) })}
          </PopBtn>

          <Divider />
        </>
      )}

      <SizeButtonWrapper>
        <PopBtn
          ref={setSizeButtonEl}
          role="menuitem"
          tabIndex={-1}
          title={t('options.changeSize')}
          aria-label={t('options.changeSizeAriaLabel', { size: sizeLabel })}
          aria-haspopup="menu"
          aria-expanded={showSizes}
          aria-controls={showSizes ? sizeMenuId : undefined}
          onKeyDown={openSizesFromArrowKey}
          {...tapProps((event) => {
            event?.stopPropagation();
            setSizesTakeFocus(isKeyboardClick(event));
            setShowSizes((prev) => !prev);
          })}
        >
          {sizeLabel}
          <IcChevron />
        </PopBtn>

        {showSizes && (
          <SizeMenu
            id={sizeMenuId}
            label={t('options.changeSize')}
            anchorEl={sizeButtonEl}
            autoFocus={sizesTakeFocus}
            onDismiss={closeSizes}
            activeSize={activeSize}
            groups={groupsClosingOnPick}
          />
        )}
      </SizeButtonWrapper>

      <Divider />

      <PopBtn
        $danger
        role="menuitem"
        tabIndex={-1}
        title={t('options.remove')}
        data-testid="remove-btn"
        aria-label={removeAriaLabel}
        // The closure is handed to the element, not run while rendering.
        // eslint-disable-next-line react-hooks/refs
        {...tapProps((event) => {
          event?.stopPropagation();
          onRemove?.();
          closeMenu();
        })}
      >
        <IcDelete /> {t('options.remove')}
      </PopBtn>
    </Popover>
  );

  return <PopoverPortal anchorEl={anchorEl}>{content}</PopoverPortal>;
};
