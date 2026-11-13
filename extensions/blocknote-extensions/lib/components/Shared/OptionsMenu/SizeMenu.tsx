import { Fragment, useEffect, useId, useRef } from 'react';
import styled from 'styled-components';
import { menuItemFocusStyles, menuSurfaceStyles } from '../../WorkPackage/atoms';
import { useAnchoredPopover } from '../../WorkPackage/anchoredPopover';
import { useTapActivation } from '../../../utils/tapActivation';
import { focusMenuItem, navigateMenu } from '../../../utils/a11y';
import type { SizeGroup } from './types';

const MENU_OFFSET = 4;
const MAX_MENU_HEIGHT = 320;

const Menu = styled.div.attrs({
  className: 'op-bn-size-menu',
  'data-testid': 'size-menu',
  role: 'menu',
})`
  position: absolute;
  top: 0;
  left: 0;
  z-index: 1;
  ${menuSurfaceStyles}
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 200px;
  overflow-y: auto;
`;

const MenuLabel = styled.div`
  padding: var(--spacer-s) var(--spacer-m);
  font-size: 0.75em;
  opacity: 0.5;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const MenuDivider = styled.div.attrs({ role: 'separator' })`
  height: 1px;
  background: var(--mantine-color-default-border);
  margin: var(--spacer-s) 0;
`;

const SizeButton = styled.button.attrs({ role: 'menuitemradio', tabIndex: -1 })<{ $active?:boolean }>`
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
  &:hover,
  &:focus-visible { background: var(--bn-colors-highlights-gray-background, #f0f0f0); }
  ${menuItemFocusStyles}
`;

const SizeButtonLabel = styled.strong`
  min-width: 28px;
`;

const SizeButtonDescription = styled.span`
  opacity: 0.6;
`;

export interface SizeMenuProps {
  id?:string;
  label:string;
  anchorEl?:HTMLElement | null;
  autoFocus?:boolean;
  // Escape closes only this menu and hands the focus back to the item that opened it.
  onDismiss:() => void;
  activeSize:string;
  groups:SizeGroup[];
}

export const SizeMenu = ({
  id,
  label,
  anchorEl,
  autoFocus = false,
  onDismiss,
  activeSize,
  groups,
}:SizeMenuProps) => {
  const menuRef = useRef<HTMLDivElement>(null);
  const tapProps = useTapActivation();
  const idPrefix = useId();

  useEffect(() => {
    if (autoFocus) focusMenuItem(menuRef.current, 'checked');
  }, [autoFocus]);

  const handleKeyDown = (event:React.KeyboardEvent<HTMLDivElement>) => {
    if (navigateMenu(event, 'vertical')) return;
    if (event.key !== 'Escape' && event.key !== 'ArrowLeft') return;
    event.preventDefault();
    event.stopPropagation();
    onDismiss();
  };

  useAnchoredPopover({
    anchorEl,
    popoverRef: menuRef,
    placement: 'below',
    offset: MENU_OFFSET,
    maxHeight: MAX_MENU_HEIGHT,
  });

  return (
    <Menu ref={menuRef} id={id} aria-label={label} onKeyDown={handleKeyDown}>
      {groups.map(({ label: groupLabel, options }, groupIndex) => (
        <Fragment key={groupLabel}>
          {groupIndex > 0 && <MenuDivider />}
          <div role="group" aria-labelledby={`${idPrefix}-group-${groupIndex}`}>
            <MenuLabel id={`${idPrefix}-group-${groupIndex}`}>{groupLabel}</MenuLabel>
            {options.map(({ key, label: optionLabel, description, pick }) => (
              <SizeButton
                key={key}
                aria-label={optionLabel}
                aria-describedby={description ? `${idPrefix}-${key}-description` : undefined}
                aria-checked={key === activeSize}
                $active={key === activeSize}
                onMouseDown={(event) => event.preventDefault()}
                // Kept from the chip the menu is rendered in, which would open the options again.
                {...tapProps((event) => {
                  event?.stopPropagation();
                  pick();
                })}
              >
                <SizeButtonLabel>{optionLabel}</SizeButtonLabel>
                {description && (
                  <SizeButtonDescription id={`${idPrefix}-${key}-description`}>
                    {description}
                  </SizeButtonDescription>
                )}
              </SizeButton>
            ))}
          </div>
        </Fragment>
      ))}
    </Menu>
  );
};
