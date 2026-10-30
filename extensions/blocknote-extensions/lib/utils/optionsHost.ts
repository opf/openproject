import { useCallback, useLayoutEffect, useRef } from 'react';

// Connects a keyboard shortcut, which only knows the selected ProseMirror node,
// to the React component rendered inside that node that owns its options menu.

const HOST_ATTRIBUTE = 'data-op-bn-options-host';

const openers = new WeakMap<Element, () => void>();

export function openOptionsWithin(nodeDom:Node):void {
  if (!(nodeDom instanceof Element)) return;

  const host = nodeDom.matches(`[${HOST_ATTRIBUTE}]`)
    ? nodeDom
    : nodeDom.querySelector(`[${HOST_ATTRIBUTE}]`);
  if (host) openers.get(host)?.();
}

export function useOptionsHost(open:() => void):(element:Element | null) => void {
  const openRef = useRef(open);
  useLayoutEffect(() => {
    openRef.current = open;
  });

  const hostRef = useRef<Element | null>(null);

  return useCallback((element:Element | null) => {
    if (hostRef.current === element) return;

    if (hostRef.current) {
      openers.delete(hostRef.current);
      hostRef.current.removeAttribute(HOST_ATTRIBUTE);
    }

    hostRef.current = element;
    if (!element) return;

    openers.set(element, () => openRef.current());
    element.setAttribute(HOST_ATTRIBUTE, '');
  }, []);
}
