import { useEffect } from 'react';
import type { RefObject } from 'react';
import { wantsMotion } from '../../utils/motion';

const DURATION = 180;
const EASING = 'ease-out';
const THRESHOLD = 1;

export interface GrowthTransitionRefs {
  panelRef:RefObject<HTMLElement | null>;
  bodyRef:RefObject<HTMLElement | null>;
  contentRef:RefObject<HTMLElement | null>;
}

export function useGrowthTransition({ panelRef, bodyRef, contentRef }:GrowthTransitionRefs):void {
  useEffect(() => {
    const panel = panelRef.current;
    const body = bodyRef.current;
    const content = contentRef.current;
    if (!panel || !body || !content) return;

    let crossedTo:number | null = null;
    let running:Animation | null = null;

    const crossToNewHeight = () => {
      const from = crossedTo;
      const to = panel.getBoundingClientRect().height;
      crossedTo = to;

      if (from === null || Math.abs(to - from) < THRESHOLD || !wantsMotion()) return;

      if (body.scrollHeight - body.clientHeight < THRESHOLD) body.dataset.growing = '';

      running = panel.animate(
        [{ height: `${from}px` }, { height: `${to}px` }],
        { duration: DURATION, easing: EASING }
      );
      running.addEventListener('finish', () => {
        running = null;
        delete body.dataset.growing;
        crossToNewHeight();
      });
    };

    const observer = new ResizeObserver(() => { if (!running) crossToNewHeight(); });
    observer.observe(content);

    return () => {
      observer.disconnect();
      running?.cancel();
      delete body.dataset.growing;
    };
  }, [panelRef, bodyRef, contentRef]);
}
