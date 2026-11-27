import { useEffect, type RefObject } from 'react';

const OPTION_SELECTOR = '[role="option"], [role="treeitem"]';

export const useActiveOptionInView = (
  listRef:RefObject<HTMLElement | null>,
  activeIndex:number,
  options:readonly unknown[],
) => {
  useEffect(() => {
    const list = listRef.current;
    if (activeIndex < 0 || !list) return undefined;

    const reveal = () => {
      list.querySelectorAll(OPTION_SELECTOR)[activeIndex]?.scrollIntoView({ block: 'nearest' });
    };
    reveal();

    // A list placed against its anchor keeps resizing after the option was revealed, which can push it out again.
    if (typeof ResizeObserver === 'undefined') return undefined;
    const observer = new ResizeObserver(reveal);
    observer.observe(list);
    return () => observer.disconnect();
  }, [listRef, activeIndex, options]);
};
