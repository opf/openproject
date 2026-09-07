import { useEffect, type RefObject } from 'react';

const OPTION_SELECTOR = '[role="option"], [role="treeitem"]';

export const useActiveOptionInView = (
  listRef:RefObject<HTMLElement | null>,
  activeIndex:number,
  options:readonly unknown[],
) => {
  useEffect(() => {
    if (activeIndex < 0) return;

    listRef.current
      ?.querySelectorAll(OPTION_SELECTOR)[activeIndex]
      ?.scrollIntoView({ block: 'nearest' });
  }, [listRef, activeIndex, options]);
};
