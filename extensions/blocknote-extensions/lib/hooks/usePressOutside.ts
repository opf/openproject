import { useEffect } from 'react';
import type { RefObject } from 'react';

// Touch is listened for in its own right: a tap another element answers never
// becomes a mousedown. composedPath() sees through a shadow root, where the
// target is retargeted to the host.
export function usePressOutside(
  elementRef:RefObject<HTMLElement | null>,
  active:boolean,
  onPressOutside:() => void,
):void {
  useEffect(() => {
    if (!active) return;
    const handlePress = (event:Event) => {
      const element = elementRef.current;
      if (element && !event.composedPath().includes(element)) onPressOutside();
    };
    document.addEventListener('mousedown', handlePress);
    document.addEventListener('touchstart', handlePress);
    return () => {
      document.removeEventListener('mousedown', handlePress);
      document.removeEventListener('touchstart', handlePress);
    };
  }, [elementRef, active, onPressOutside]);
}
