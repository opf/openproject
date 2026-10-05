import { useRef } from 'react';
import { useTranslation } from 'react-i18next';
import styled from 'styled-components';
import { CheckIcon } from '@primer/octicons-react';
import { defaultWpVariables, menuSurfaceStyles } from '../WorkPackage/atoms';
import { PopoverPortal, useAnchoredPopover } from '../WorkPackage/anchoredPopover';
import { FLOATING_Z_INDEX } from '../../utils/zIndex';
import { useTapActivation } from '../../utils/tapActivation';
import type { AttributeDisplay } from './externalHtml';

const MENU_OFFSET = 4;
const MAX_MENU_HEIGHT = 200;
const DISPLAYS:AttributeDisplay[] = ['label', 'value', 'both'];

const Menu = styled.div.attrs({
  className: 'op-bn-wp-attribute-menu',
  role: 'menu',
  'data-testid': 'attribute-display-menu',
})`
  ${defaultWpVariables}
  --op-attribute-menu-label: var(--fgColor-muted, #59636e);

  [data-color-scheme="dark"] & {
    --op-attribute-menu-label: var(--fgColor-muted, #9198a1);
  }

  position: absolute;
  z-index: ${FLOATING_Z_INDEX.options};
  ${menuSurfaceStyles}
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  min-width: 180px;
  line-height: 1.4;
`;

const MenuLabel = styled.div`
  padding: var(--spacer-s) var(--spacer-m);
  font-size: 0.75em;
  color: var(--op-attribute-menu-label);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const MenuItem = styled.button.attrs({ type: 'button', role: 'menuitemradio' })`
  display: flex;
  align-items: center;
  gap: var(--spacer-m);
  width: 100%;
  background: none;
  border: none;
  border-radius: var(--bn-border-radius-small);
  padding: var(--spacer-s) var(--spacer-m);
  cursor: pointer;
  font-size: 0.85em;
  color: var(--bn-colors-editor-text, #333);
  text-align: left;
  &:hover { background: var(--bn-colors-highlights-gray-background, #f0f0f0); }
`;

const Check = styled.span<{ $visible:boolean }>`
  display: inline-flex;
  width: 16px;
  visibility: ${({ $visible }) => ($visible ? 'visible' : 'hidden')};
`;

export interface AttributeDisplayMenuProps {
  anchorEl:HTMLElement | null;
  active:AttributeDisplay;
  onPick:(display:AttributeDisplay) => void;
}

export const AttributeDisplayMenu = ({ anchorEl, active, onPick }:AttributeDisplayMenuProps) => {
  const { t } = useTranslation();
  const menuRef = useRef<HTMLDivElement>(null);
  const tapProps = useTapActivation();

  useAnchoredPopover({
    anchorEl,
    popoverRef: menuRef,
    placement: 'below',
    offset: MENU_OFFSET,
    maxHeight: MAX_MENU_HEIGHT,
  });

  return (
    <PopoverPortal anchorEl={anchorEl}>
      <Menu
        ref={menuRef}
        aria-label={t('workPackageAttribute.dialog.show')}
        // Kept from the document, where a press closes the menu as outside the chip.
        onMouseDown={(event) => event.stopPropagation()}
        onTouchStart={(event) => event.stopPropagation()}
      >
        <MenuLabel>{t('workPackageAttribute.dialog.show')}</MenuLabel>
        {DISPLAYS.map((display) => (
          <MenuItem
            key={display}
            aria-checked={display === active}
            onMouseDown={(event) => event.preventDefault()}
            {...tapProps((event) => {
              event?.stopPropagation();
              onPick(display);
            })}
          >
            <Check $visible={display === active}><CheckIcon size={16} /></Check>
            {t(`workPackageAttribute.display.${display}`)}
          </MenuItem>
        ))}
      </Menu>
    </PopoverPortal>
  );
};
