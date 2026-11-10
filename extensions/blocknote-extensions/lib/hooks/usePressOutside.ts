import { useEffect, useRef } from 'react';
import type { RefObject } from 'react';

/**
 * Calls back when the pointer presses anywhere but the given element, while active.
 * Touch is listened for in its own right: a tap another element answers never
 * becomes a mousedown. The composed path sees through shadow roots, which
 * retarget the event to their host.
 */
export function usePressOutside(
  elementRef:RefObject<HTMLElement | null>,
  active:boolean,
  onPressOutside:() => void,
):void {
  const callbackRef = useRef(onPressOutside);
  useEffect(() => {
    callbackRef.current = onPressOutside;
  });

  useEffect(() => {
    if (!active) return;
    const handlePress = (event:Event) => {
      const element = elementRef.current;
      if (element && !event.composedPath().includes(element)) callbackRef.current();
    };
    document.addEventListener('mousedown', handlePress);
    document.addEventListener('touchstart', handlePress);
    return () => {
      document.removeEventListener('mousedown', handlePress);
      document.removeEventListener('touchstart', handlePress);
    };
  }, [active, elementRef]);
}
