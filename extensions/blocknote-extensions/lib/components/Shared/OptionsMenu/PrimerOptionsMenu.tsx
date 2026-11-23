import { Fragment, useEffect, useEffectEvent, useRef, useState } from 'react';
import { EyeIcon, LinkExternalIcon, TrashIcon } from '@primer/octicons-react';
import { useTranslation } from 'react-i18next';
import { linkToWorkPackage } from '../../../services/openProjectApi';
import type { PrimerDialogComponents } from '../../../services/dialogComponents';
import { formatWorkPackageId } from '../../../utils/id';
import { useTapActivation } from '../../../utils/tapActivation';
import type { OptionsPopoverProps } from './OptionsPopover';

import styled from 'styled-components';
import { PopoverPortal, useAnchoredPopover } from '../../WorkPackage/anchoredPopover';
import { FLOATING_Z_INDEX } from '../../../utils/zIndex';

const Toolbar = styled.div`
  position: absolute;
  z-index: ${FLOATING_Z_INDEX.options};
  display: flex;
  align-items: center;
  gap: var(--base-size-4, 4px);
  padding: var(--base-size-4, 4px);
  background: var(--overlay-bgColor, white);
  border: 1px solid var(--borderColor-muted, #d1d9e0);
  border-radius: var(--borderRadius-large, 12px);
  box-shadow: var(--shadow-floating-medium);
  width: max-content;
  > button svg { width: 20px; height: 20px; }
`;

export function PrimerOptionsMenu({
  primer: { ActionMenu, ActionList, IconButton }, anchorEl, openId, ariaLabel, removeAriaLabel, sizeGroups, activeSize,
  onClose, onRestoreFocus, onRemove, autoFocus,
}:OptionsPopoverProps & { primer:PrimerDialogComponents }) {
  const { t } = useTranslation();
  const toolbar = useRef<HTMLDivElement>(null);
  const showButton = useRef<HTMLButtonElement>(null);
  const [showSizes, setShowSizes] = useState(false);
  const tapProps = useTapActivation();
  const show = t('workPackageAttribute.dialog.show');
  useAnchoredPopover({ anchorEl, popoverRef: toolbar, placement: 'above' });

  const close = () => {
    onClose();
    if (onRestoreFocus) requestAnimationFrame(onRestoreFocus);
  };

  const dismiss = useEffectEvent((event:KeyboardEvent) => {
    const backToShow = showSizes && (event.key === 'Escape' || event.key === 'ArrowLeft');
    if (!backToShow && event.key !== 'Escape' && event.key !== 'Tab') return;
    event.preventDefault();
    event.stopPropagation();
    if (backToShow) {
      setShowSizes(false);
      showButton.current?.focus();
    } else {
      close();
    }
  });
  useEffect(() => {
    document.addEventListener('keydown', dismiss, true);
    return () => document.removeEventListener('keydown', dismiss, true);
  }, []);
  useEffect(() => {
    if (autoFocus) toolbar.current?.querySelector('button')?.focus();
  }, [autoFocus]);

  const action = (run:() => void) => tapProps(event => {
    event?.stopPropagation();
    run();
    close();
  });
  const trigger = tapProps(() => setShowSizes(value => !value));

  return (
    <PopoverPortal anchorEl={anchorEl}>
      <Toolbar ref={toolbar} role="toolbar" aria-label={ariaLabel} data-testid="popover-content"
        onMouseDown={event => event.stopPropagation()} onTouchStart={event => event.stopPropagation()} onClick={event => event.stopPropagation()}
        onKeyDown={event => {
          if (showSizes || !(event.target instanceof HTMLButtonElement)) return;
          const buttons = Array.from(event.currentTarget.querySelectorAll('button'));
          const i = buttons.indexOf(event.target);
          const positions:Partial<Record<string, number>> = {
            ArrowLeft: (i + buttons.length - 1) % buttons.length, ArrowRight: (i + 1) % buttons.length, Home: 0, End: buttons.length - 1,
          };
          const next = positions[event.key];
          if (next === undefined) return;
          event.preventDefault();
          event.stopPropagation();
          buttons[next].focus();
        }}>
        {openId && (
          <IconButton icon={LinkExternalIcon} variant="invisible" size="medium" aria-label={t('options.openAriaLabel', { id: formatWorkPackageId(openId) })}
            {...action(() => window.open(linkToWorkPackage(openId), '_blank', 'noopener,noreferrer'))} />
        )}
        <ActionMenu anchorRef={showButton} open={showSizes} onOpenChange={setShowSizes}>
          <ActionMenu.Button leadingVisual={EyeIcon} size="medium" variant="invisible" onTouchStart={trigger.onTouchStart} onTouchEnd={trigger.onTouchEnd}>
            {show}
          </ActionMenu.Button>
          <ActionMenu.Overlay data-testid="size-menu" displayInViewport maxHeight="medium" overflow="auto"
            style={{ width: 'min(22rem, calc(100vw - 1rem))', whiteSpace: 'normal', overflowWrap: 'anywhere' }}>
            <ActionList aria-label={show}>
              {sizeGroups.map(({ label, options }, index) => (
                <Fragment key={label}>
                  {index > 0 && <ActionList.Divider />}
                  <ActionList.Group selectionVariant="single">
                    <ActionList.GroupHeading>{label}</ActionList.GroupHeading>
                    {options.map(option => {
                      const tap = action(option.pick);
                      return (
                        <ActionList.Item key={option.key} selected={option.key === activeSize}
                          onTouchStart={tap.onTouchStart} onTouchEnd={tap.onTouchEnd} onSelect={event => {
                            event.preventDefault();
                            if ('key' in event) { option.pick(); close(); }
                            else tap.onClick(event);
                          }}>
                          {option.label}
                          {option.description && <ActionList.Description variant="block" style={{ whiteSpace: 'normal' }}>{option.description}</ActionList.Description>}
                        </ActionList.Item>
                      );
                    })}
                  </ActionList.Group>
                </Fragment>
              ))}
            </ActionList>
          </ActionMenu.Overlay>
        </ActionMenu>
        {onRemove && (
          <IconButton icon={TrashIcon} variant="invisible" size="medium" aria-label={removeAriaLabel} data-testid="remove-btn"
            style={{ color: 'var(--fgColor-danger)' }} {...action(onRemove)} />
        )}
      </Toolbar>
    </PopoverPortal>
  );
}
