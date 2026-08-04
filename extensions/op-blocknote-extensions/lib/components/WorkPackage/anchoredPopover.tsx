import {
  useEffect,
  useLayoutEffect,
  useState,
  type ReactNode,
  type RefObject,
} from 'react';
import { createPortal } from 'react-dom';

const DEFAULT_ANCHOR_OFFSET = 6;
const VIEWPORT_MARGIN = 8;
const MIN_POPOVER_HEIGHT = 80;

// For a chip wrapped across lines, getBoundingClientRect() returns the union of
// its line fragments (left edge = start of line). The first fragment is where
// the link actually starts, so anchor to it.
const getAnchorRect = (el:HTMLElement):DOMRect =>
  el.getClientRects()[0] ?? el.getBoundingClientRect();

export interface AnchoredPopoverOptions {
  anchorEl?:HTMLElement | null;
  popoverRef:RefObject<HTMLElement | null>;
  placement:'above' | 'below';
  offset?:number;
  onClose:() => void;
  // When false, a scroll repositions the popover instead of closing it.
  closeOnScroll?:boolean;
  matchAnchorWidth?:boolean;
  maxHeight?:number;
  // Any value that changes when the content changes size.
  resizeKey?:unknown;
}

export const useAnchoredPopover = ({
  anchorEl,
  popoverRef,
  placement,
  offset = DEFAULT_ANCHOR_OFFSET,
  onClose,
  closeOnScroll = true,
  matchAnchorWidth = false,
  maxHeight,
  resizeKey,
}:AnchoredPopoverOptions) => {
  const [anchorRect, setAnchorRect] = useState<DOMRect | null>(
    () => (anchorEl ? getAnchorRect(anchorEl) : null)
  );

  useEffect(() => {
    if (!anchorEl) return;
    const update = () => setAnchorRect(getAnchorRect(anchorEl));

    // Coalesce reposition work to one run per frame - scroll fires far faster.
    let frame = 0;
    const scheduleUpdate = () => {
      if (frame) return;
      frame = requestAnimationFrame(() => { frame = 0; update(); });
    };
    const handleScroll = () => (closeOnScroll ? onClose() : scheduleUpdate());

    update();
    window.addEventListener('scroll', handleScroll, true);
    window.addEventListener('resize', scheduleUpdate);
    return () => {
      if (frame) cancelAnimationFrame(frame);
      window.removeEventListener('scroll', handleScroll, true);
      window.removeEventListener('resize', scheduleUpdate);
    };
  }, [anchorEl, onClose, closeOnScroll]);

  // Position before paint so the popover never flashes at its CSS fallback spot.
  useLayoutEffect(() => {
    const popover = popoverRef.current;
    if (!anchorRect || !popover) return;

    if (matchAnchorWidth) popover.style.width = `${anchorRect.width}px`;
    if (maxHeight !== undefined) popover.style.maxHeight = `${maxHeight}px`;

    const { offsetWidth: width, offsetHeight: height } = popover;
    const spaceAbove = anchorRect.top - offset - VIEWPORT_MARGIN;
    const spaceBelow = window.innerHeight - anchorRect.bottom - offset - VIEWPORT_MARGIN;
    const fitsPreferred = height <= (placement === 'above' ? spaceAbove : spaceBelow);
    const resolved = fitsPreferred
      ? placement
      : (spaceAbove >= spaceBelow ? 'above' : 'below');

    const left = Math.max(
      VIEWPORT_MARGIN,
      Math.min(anchorRect.left, window.innerWidth - width - VIEWPORT_MARGIN)
    );

    popover.style.position = 'fixed';
    popover.style.left = `${left}px`;
    if (maxHeight !== undefined) {
      const space = resolved === 'above' ? spaceAbove : spaceBelow;
      popover.style.maxHeight = `${Math.min(maxHeight, Math.max(MIN_POPOVER_HEIGHT, space))}px`;
    }
    if (resolved === 'above') {
      popover.style.bottom = `${window.innerHeight - anchorRect.top + offset}px`;
      popover.style.top = 'auto';
    } else {
      popover.style.top = `${anchorRect.bottom + offset}px`;
      popover.style.bottom = 'auto';
    }
  }, [anchorRect, placement, offset, popoverRef, matchAnchorWidth, maxHeight, resizeKey]);
};

export const PopoverPortal = ({
  anchorEl,
  children,
}:{ anchorEl?:HTMLElement | null; children:ReactNode }) => {
  if (!anchorEl) return <>{children}</>;
  return createPortal(children, anchorEl.closest('.bn-container') ?? document.body);
};
