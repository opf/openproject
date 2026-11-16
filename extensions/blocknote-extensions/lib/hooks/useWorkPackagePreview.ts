import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { supportsHover } from '../utils/device';

const PREVIEW_OPEN_DELAY = 300;
const PREVIEW_CLOSE_DELAY = 150;

interface UseWorkPackagePreviewOptions {
  // Only tiny (xxs) chips show just the ID, so only they get a preview trigger.
  enabled:boolean;
  // Suppress opening while another popover (the options menu) owns the chip.
  suppressed:boolean;
  // Called before the preview opens, for the caller to clear what suppressed it.
  onOpen?:() => void;
}

interface ChipHoverProps {
  onMouseEnter:() => void;
  onMouseLeave:() => void;
}

export interface ChipIndicatorProps {
  expanded:boolean;
  toggle:() => void;
}

export interface WorkPackagePreview {
  previewOpen:boolean;
  closePreview:() => void;
  triggerProps:ChipHoverProps | undefined;
  indicatorProps:ChipIndicatorProps | undefined;
  cardProps:Partial<ChipHoverProps>;
}

export function useWorkPackagePreview({ enabled, suppressed, onOpen }:UseWorkPackagePreviewOptions):WorkPackagePreview {
  const canHover = useMemo(() => supportsHover(), []);

  const [previewOpen, setPreviewOpen] = useState(false);
  const openTimer = useRef<number | undefined>(undefined);
  const closeTimer = useRef<number | undefined>(undefined);

  const clearTimers = useCallback(() => {
    window.clearTimeout(openTimer.current);
    window.clearTimeout(closeTimer.current);
  }, []);

  useEffect(() => clearTimers, [clearTimers]);

  // Stable identity: the chip closes the preview from an effect keyed on it, so
  // it must not change every render.
  const closePreview = useCallback(() => {
    clearTimers();
    setPreviewOpen(false);
  }, [clearTimers]);

  const handlePreviewEnter = () => {
    if (suppressed) return;
    clearTimers();
    openTimer.current = window.setTimeout(() => setPreviewOpen(true), PREVIEW_OPEN_DELAY);
  };

  const handlePreviewLeave = () => {
    clearTimers();
    closeTimer.current = window.setTimeout(() => setPreviewOpen(false), PREVIEW_CLOSE_DELAY);
  };

  const togglePreview = () => {
    if (previewOpen) {
      closePreview();
      return;
    }
    onOpen?.();
    setPreviewOpen(true);
  };

  return {
    previewOpen,
    closePreview,
    triggerProps: enabled && canHover
      ? { onMouseEnter: handlePreviewEnter, onMouseLeave: handlePreviewLeave }
      : undefined,
    indicatorProps: enabled && !canHover
      ? { expanded: previewOpen, toggle: togglePreview }
      : undefined,
    cardProps: canHover ? { onMouseEnter: clearTimers, onMouseLeave: handlePreviewLeave } : {},
  };
}
