import { useRef, type ReactNode } from 'react';
import styled from 'styled-components';
import { defaultWpVariables } from './atoms';
import { useAnchoredPopover, PopoverPortal } from './anchoredPopover';
import { FLOATING_Z_INDEX } from './tokens';

const PreviewContainer = styled.div.attrs({
  className: 'op-bn-wp-preview',
  'data-testid': 'wp-preview',
})`
  ${defaultWpVariables}
  position: absolute;
  z-index: ${FLOATING_Z_INDEX.preview};
  top: calc(100% + 6px);
  left: 0;
  width: max-content;
  max-width: min(420px, calc(100vw - 24px));
  background-color: var(--bn-colors-menu-background, #fff);
  box-shadow: var(--bn-shadow-medium);
  border-radius: var(--bn-border-radius-large);
  padding: var(--spacer-s);
  cursor: default;
`;

export interface WpPreviewPopoverProps {
  anchorEl?:HTMLElement | null;
  onMouseEnter?:() => void;
  onMouseLeave?:() => void;
  children:ReactNode;
}

// Hover/long-press preview for tiny (xxs) inline chips.
export const WpPreviewPopover = ({
  anchorEl,
  onMouseEnter,
  onMouseLeave,
  children,
}:WpPreviewPopoverProps) => {
  const containerRef = useRef<HTMLDivElement | null>(null);
  useAnchoredPopover({ anchorEl, popoverRef: containerRef, placement: 'below' });

  return (
    <PopoverPortal anchorEl={anchorEl}>
      {/* Prevent editor/parent handlers from stealing focus while interacting with the preview */}
      <PreviewContainer
        ref={containerRef}
        onMouseDown={(e) => e.stopPropagation()}
        onClick={(e) => e.stopPropagation()}
        onMouseEnter={onMouseEnter}
        onMouseLeave={onMouseLeave}
      >
        {children}
      </PreviewContainer>
    </PopoverPortal>
  );
};
