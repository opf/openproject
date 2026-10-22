import { useRef } from 'react';
import type { MouseEvent as ReactMouseEvent, TouchEvent as ReactTouchEvent } from 'react';

// A finger never lands perfectly still; beyond this the gesture was a scroll.
const TAP_MOVE_TOLERANCE = 10;

// Preventing the touch's default should already stop the mouse sequence, but a
// browser that replays it anyway must not activate the element twice.
const GHOST_CLICK_WINDOW = 700;

// Only the mouse path has an event to hand over, for callers that have to keep
// the click away from the outside-press handlers.
export type TapAction = (event?:ReactMouseEvent) => void;

export interface TapActivationProps {
  onTouchStart:(event:ReactTouchEvent) => void;
  onTouchEnd:(event:ReactTouchEvent) => void;
  onClick:(event:ReactMouseEvent) => void;
}

/*
 * Activates an element from the touch itself instead of from the click iOS
 * Safari synthesises afterwards: it holds that click back until the second tap
 * on everything our editor UI is built from. Preventing the touch's default
 * suppresses the replayed mouse sequence, so a mouse still activates exactly
 * once, through `onClick`.
 *
 * A touch that landed in a React portal (a popover anchored to the element)
 * bubbles up the React tree to the element it was rendered from, and a nested
 * link or button answers for itself - neither is a tap on the element.
 */
export function useTapActivation():(activate:TapAction) => TapActivationProps {
  const startedAt = useRef<{ x:number; y:number } | null>(null);
  const activatedAt = useRef(Number.NEGATIVE_INFINITY);

  const isOwnTouch = (event:ReactTouchEvent) => {
    const target = event.target;
    if (!(target instanceof Element)) return false;
    if (!event.currentTarget.contains(target)) return false;

    const nested = target.closest('a, button');
    return !nested || nested === event.currentTarget;
  };

  return (activate:TapAction) => ({
    onTouchStart: (event:ReactTouchEvent) => {
      const touch = event.changedTouches[0];
      startedAt.current = touch && isOwnTouch(event) ? { x: touch.clientX, y: touch.clientY } : null;
    },
    onTouchEnd: (event:ReactTouchEvent) => {
      const start = startedAt.current;
      const touch = event.changedTouches[0];
      startedAt.current = null;
      if (!start || !touch || !isOwnTouch(event)) return;
      if (Math.hypot(touch.clientX - start.x, touch.clientY - start.y) > TAP_MOVE_TOLERANCE) return;

      event.preventDefault();
      activatedAt.current = event.timeStamp;
      activate();
    },
    onClick: (event:ReactMouseEvent) => {
      if (event.timeStamp - activatedAt.current < GHOST_CLICK_WINDOW) return;
      activate(event);
    },
  });
}
