import { useEffect, useState, type RefObject } from 'react';

export const useElementHeight = (ref:RefObject<HTMLElement | null>):number => {
  const [height, setHeight] = useState(0);

  useEffect(() => {
    const element = ref.current;
    if (!element || typeof ResizeObserver === 'undefined') return;

    const observer = new ResizeObserver(() => setHeight(element.offsetHeight));
    observer.observe(element);
    return () => observer.disconnect();
  }, [ref]);

  return height;
};
