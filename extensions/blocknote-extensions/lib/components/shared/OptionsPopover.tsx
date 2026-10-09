import { useRef } from 'react';
import type { ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import styled from 'styled-components';
import { LinkExternalIcon, TrashIcon } from '@primer/octicons-react';
import { editorThemeVariables, menuSurfaceStyles } from './theme';
import { useAnchoredPopover, PopoverPortal } from './anchoredPopover';
import { FLOATING_Z_INDEX } from '../../utils/zIndex';
import { useTapActivation } from '../../utils/tapActivation';

export interface OptionsPopoverProps {
  anchorEl?:HTMLElement | null;
  // Without an href there is nothing to open, so the Open button is left out.
  openHref?:string;
  openAriaLabel?:string;
  removeAriaLabel:string;
  onRemove?:() => void;
  onClose:() => void;
  // Extra sections between Open and Remove.
  children?:ReactNode;
}

const Popover = styled.div.attrs({
  className: 'op-bn-inline-options',
  'data-testid': 'popover-content',
})`
  ${editorThemeVariables}
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

export const OptionsButton = styled.button<{ $danger?:boolean }>`
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

export const OptionsPopover = ({
  anchorEl,
  openHref,
  openAriaLabel,
  removeAriaLabel,
  onRemove,
  onClose,
  children,
}:OptionsPopoverProps) => {
  const { t } = useTranslation();
  const tapProps = useTapActivation();
  const popoverRef = useRef<HTMLDivElement | null>(null);
  useAnchoredPopover({ anchorEl, popoverRef, placement: 'above' });

  const content = (
    // stopPropagation stops the outside-tap handlers from closing the popover.
    // Do NOT add preventDefault: on iOS it suppresses the first tap's click, so
    // every button then needs a priming tap.
    <Popover
      ref={popoverRef}
      onMouseDown={(e) => e.stopPropagation()}
      onTouchStart={(e) => e.stopPropagation()}
    >
      {openHref && (
        <>
          <OptionsButton
            title={t('options.openInNewTab')}
            aria-label={openAriaLabel}
            {...tapProps((event) => {
              event?.stopPropagation();
              window.open(openHref, '_blank', 'noopener,noreferrer');
            })}
          >
            <LinkExternalIcon size={13} /> {t('options.open')}
          </OptionsButton>

          <Divider />
        </>
      )}

      {children && (
        <>
          {children}
          <Divider />
        </>
      )}

      <OptionsButton
        $danger
        title={t('options.remove')}
        data-testid="remove-btn"
        aria-label={removeAriaLabel}
        {...tapProps((event) => {
          event?.stopPropagation();
          onRemove?.();
          onClose();
        })}
      >
        <TrashIcon size={13} /> {t('options.remove')}
      </OptionsButton>
    </Popover>
  );

  return <PopoverPortal anchorEl={anchorEl}>{content}</PopoverPortal>;
};
