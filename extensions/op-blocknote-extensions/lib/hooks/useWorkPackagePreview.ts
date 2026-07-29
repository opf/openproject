import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type MouseEvent as ReactMouseEvent,
  type PointerEvent as ReactPointerEvent,
} from 'react';
import { supportsHover } from '../utils/device';

const PREVIEW_OPEN_DELAY = 300;
const PREVIEW_CLOSE_DELAY = 150;

// Touch devices open the preview with a long press instead of a hover.
const LONG_PRESS_DELAY = 500;
const LONG_PRESS_MOVE_TOLERANCE = 10;

interface UseWorkPackagePreviewOptions {
  // Only tiny (xxs) chips show just the ID, so only they get a preview trigger.
  enabled:boolean;
  // Suppress opening while another popover (the options menu) owns the chip.
  suppressed:boolean;
}

interface ChipTriggerProps {
  onMouseEnter:() => void;
  onMouseLeave:() => void;
  onPointerDown:(e:ReactPointerEvent) => void;
  onPointerUp:() => void;
  onPointerMove:(e:ReactPointerEvent) => void;
  onPointerCancel:() => void;
  onContextMenu:((e:ReactMouseEvent) => void) | undefined;
  // Claim the touch gesture so the browser doesn't start panning and fire
  // pointercancel mid-press, which used to make the long press fire only sometimes.
  style:{ touchAction:'none' };
}

interface WorkPackagePreview {
  previewOpen:boolean;
  closePreview:() => void;
  // True at most once per press: the click that follows a long press, so the
  // caller can swallow it instead of treating it as a tap.
  wasLongPress:() => boolean;
  triggerProps:ChipTriggerProps | undefined;
  cardProps:{ onMouseEnter:() => void; onMouseLeave:() => void };
}

// Encapsulates the hover (desktop) / long-press (touch) preview trigger for an
// inline work package chip: open/close timing, touch long-press detection, and
// the props to wire onto the chip and the preview card.
export function useWorkPackagePreview({ enabled, suppressed }:UseWorkPackagePreviewOptions):WorkPackagePreview {
  const canHover = useMemo(() => supportsHover(), []);

  const [previewOpen, setPreviewOpen] = useState(false);
  const openTimer = useRef<number | undefined>(undefined);
  const closeTimer = useRef<number | undefined>(undefined);

  const longPressTimer = useRef<number | undefined>(undefined);
  const longPressFired = useRef(false);
  const longPressStart = useRef<{ x:number; y:number } | null>(null);

  const clearTimers = useCallback(() => {
    window.clearTimeout(openTimer.current);
    window.clearTimeout(closeTimer.current);
  }, []);

  useEffect(
    () => () => {
      clearTimers();
      window.clearTimeout(longPressTimer.current);
    },
    [clearTimers]
  );

  // Stable identity: the popover's positioning effect subscribes scroll/resize
  // listeners keyed on onClose, so it must not change every render.
  const closePreview = useCallback(() => {
    clearTimers();
    setPreviewOpen(false);
  }, [clearTimers]);

  const handlePreviewEnter = () => {
    if (!canHover || suppressed) return;
    clearTimers();
    openTimer.current = window.setTimeout(() => setPreviewOpen(true), PREVIEW_OPEN_DELAY);
  };

  // On touch the preview stays until an outside tap, so only hover closes on pointer-out.
  const handlePreviewLeave = () => {
    if (!canHover) return;
    clearTimers();
    closeTimer.current = window.setTimeout(() => setPreviewOpen(false), PREVIEW_CLOSE_DELAY);
  };

  const handleLongPressStart = (e:ReactPointerEvent) => {
    if (canHover) return;
    // Clear any in-flight timer so a second pointer (multi-touch) can't orphan it
    // and fire a spurious open after both fingers have lifted.
    window.clearTimeout(longPressTimer.current);
    longPressStart.current = { x: e.clientX, y: e.clientY };
    longPressFired.current = false;
    longPressTimer.current = window.setTimeout(() => {
      longPressFired.current = true;
      setPreviewOpen(true);
    }, LONG_PRESS_DELAY);
  };

  const cancelLongPress = () => window.clearTimeout(longPressTimer.current);

  const handleLongPressMove = (e:ReactPointerEvent) => {
    const start = longPressStart.current;
    if (!start) return;
    if (Math.hypot(e.clientX - start.x, e.clientY - start.y) > LONG_PRESS_MOVE_TOLERANCE)
      cancelLongPress();
  };

  const wasLongPress = () => {
    if (!longPressFired.current) return false;
    longPressFired.current = false;
    return true;
  };

  const triggerProps = enabled
    ? {
        onMouseEnter: handlePreviewEnter,
        onMouseLeave: handlePreviewLeave,
        onPointerDown: handleLongPressStart,
        onPointerUp: cancelLongPress,
        onPointerMove: handleLongPressMove,
        onPointerCancel: cancelLongPress,
        onContextMenu: canHover ? undefined : (e:ReactMouseEvent) => e.preventDefault(),
        style: { touchAction: 'none' as const },
      }
    : undefined;

  return {
    previewOpen,
    closePreview,
    wasLongPress,
    triggerProps,
    cardProps: { onMouseEnter: clearTimers, onMouseLeave: handlePreviewLeave },
  };
}
