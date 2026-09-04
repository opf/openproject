import {
  useEffect,
  useLayoutEffect,
  useState,
  type ReactNode,
  type RefObject,
} from 'react';
import { createPortal } from 'react-dom';

const DEFAULT_ANCHOR_OFFSET = 6;
const CLIP_MARGIN = 8;
const MIN_POPOVER_HEIGHT = 80;

type Side = 'above' | 'below';

interface VisibleRect {
  top:number;
  left:number;
  right:number;
  bottom:number;
}

const clamp = (value:number, min:number, max:number):number =>
  Math.max(min, Math.min(value, max));

// For a chip wrapped across lines, getBoundingClientRect() returns the union of
// its line fragments (left edge = start of line). The first fragment is where
// the link actually starts, so anchor to it.
const getAnchorRect = (el:HTMLElement):DOMRect =>
  el.getClientRects()[0] ?? el.getBoundingClientRect();

const isSameRect = (a:DOMRect, b:DOMRect):boolean =>
  a.top === b.top && a.left === b.left && a.width === b.width && a.height === b.height;

const getParentElement = (element:Element):Element | null => {
  if (element.parentElement) return element.parentElement;
  const root = element.getRootNode();
  return root instanceof ShadowRoot ? root.host : null;
};

// A fixed popover is taken out of the flow, so only the viewport clips it; an
// absolute one is also clipped by every scrolling ancestor above it.
const getVisibleRect = (element:HTMLElement):VisibleRect => {
  const visible:VisibleRect = {
    top: 0,
    left: 0,
    right: window.innerWidth,
    bottom: window.innerHeight,
  };

  if (getComputedStyle(element).position === 'fixed') return visible;

  for (let parent = getParentElement(element); parent; parent = getParentElement(parent)) {
    const { overflowX, overflowY } = getComputedStyle(parent);
    if (overflowX === 'visible' && overflowY === 'visible') continue;

    const rect = parent.getBoundingClientRect();
    visible.top = Math.max(visible.top, rect.top);
    visible.left = Math.max(visible.left, rect.left);
    visible.right = Math.min(visible.right, rect.right);
    visible.bottom = Math.min(visible.bottom, rect.bottom);
  }

  return visible;
};

const getSpaces = (
  anchorRect:DOMRect,
  visible:VisibleRect,
  offset:number,
):Record<Side, number> => ({
  above: anchorRect.top - visible.top - offset - CLIP_MARGIN,
  below: visible.bottom - anchorRect.bottom - offset - CLIP_MARGIN,
});

const resolveSide = (preferred:Side, height:number, spaces:Record<Side, number>):Side => {
  if (height <= spaces[preferred]) return preferred;

  return spaces.above >= spaces.below ? 'above' : 'below';
};

// Where the popover lands with no offsets applied, so the styles below can be
// expressed in viewport coordinates whatever the containing block is.
const getOrigin = (popover:HTMLElement):DOMRect => {
  popover.style.bottom = 'auto';
  popover.style.left = '0px';
  popover.style.top = '0px';

  return popover.getBoundingClientRect();
};

const positionPopover = (
  popover:HTMLElement,
  anchorRect:DOMRect,
  placement:Side,
  offset:number,
  maxHeight?:number,
) => {
  // Undo an earlier run's cap first - the side is chosen from the natural height.
  if (maxHeight !== undefined) popover.style.maxHeight = `${maxHeight}px`;

  const origin = getOrigin(popover);
  const visible = getVisibleRect(popover);
  const spaces = getSpaces(anchorRect, visible, offset);
  const side = resolveSide(placement, popover.offsetHeight, spaces);

  if (maxHeight !== undefined) {
    const visibleHeight = Math.max(0, visible.bottom - visible.top - CLIP_MARGIN * 2);
    const room = Math.min(visibleHeight, Math.max(MIN_POPOVER_HEIGHT, spaces[side]));
    popover.style.maxHeight = `${Math.min(maxHeight, room)}px`;
  }

  // Read after the cap, or a shortened popover would be placed by its full height.
  const { offsetWidth: width, offsetHeight: height } = popover;

  const anchoredTop = side === 'above'
    ? anchorRect.top - offset - height
    : anchorRect.bottom + offset;

  // Clamping keeps every button reachable where the popover would still cross an edge.
  const left = clamp(anchorRect.left, visible.left + CLIP_MARGIN, visible.right - width - CLIP_MARGIN);
  const top = clamp(anchoredTop, visible.top + CLIP_MARGIN, visible.bottom - height - CLIP_MARGIN);

  popover.style.left = `${left - origin.left}px`;
  popover.style.top = `${top - origin.top}px`;
};

export interface AnchoredPopoverOptions {
  anchorEl?:HTMLElement | null;
  popoverRef:RefObject<HTMLElement | null>;
  placement:'above' | 'below';
  offset?:number;
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
  matchAnchorWidth = false,
  maxHeight,
  resizeKey,
}:AnchoredPopoverOptions) => {
  const [anchorRect, setAnchorRect] = useState<DOMRect | null>(
    () => (anchorEl ? getAnchorRect(anchorEl) : null)
  );

  useEffect(() => {
    if (!anchorEl) return;
    // The chip rerenders on every editor transaction, and a fresh DOMRect would
    // reposition the popover on each of them.
    const update = () => setAnchorRect((previous) => {
      const next = getAnchorRect(anchorEl);
      return previous && isSameRect(previous, next) ? previous : next;
    });

    // Coalesce reposition work to one run per frame - resize fires far faster.
    let frame = 0;
    const scheduleUpdate = () => {
      if (frame) return;
      frame = requestAnimationFrame(() => { frame = 0; update(); });
    };

    const handleScroll = () => {
      const popover = popoverRef.current;
      if (popover && getComputedStyle(popover).position === 'fixed') scheduleUpdate();
    };

    update();
    window.addEventListener('scroll', handleScroll, true);
    window.addEventListener('resize', scheduleUpdate);
    // A popover opened on a field that is still animating in was measured
    // against a position the anchor has since left.
    window.addEventListener('animationend', scheduleUpdate, true);
    window.addEventListener('transitionend', scheduleUpdate, true);
    return () => {
      if (frame) cancelAnimationFrame(frame);
      window.removeEventListener('scroll', handleScroll, true);
      window.removeEventListener('resize', scheduleUpdate);
      window.removeEventListener('animationend', scheduleUpdate, true);
      window.removeEventListener('transitionend', scheduleUpdate, true);
    };
  }, [anchorEl, popoverRef]);

  // Position before paint so the popover never flashes at its CSS fallback spot.
  useLayoutEffect(() => {
    const popover = popoverRef.current;
    if (!anchorRect || !popover) return;

    if (matchAnchorWidth) popover.style.width = `${anchorRect.width}px`;

    positionPopover(popover, anchorRect, placement, offset, maxHeight);
  }, [anchorRect, placement, offset, popoverRef, matchAnchorWidth, maxHeight, resizeKey]);
};

export const PopoverPortal = ({
  anchorEl,
  children,
}:{ anchorEl?:HTMLElement | null; children:ReactNode }) => {
  if (!anchorEl) return <>{children}</>;
  return createPortal(children, anchorEl.closest('.bn-container') ?? document.body);
};
