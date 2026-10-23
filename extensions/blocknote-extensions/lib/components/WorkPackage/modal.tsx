import { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { StyleSheetManager } from 'styled-components';

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
].join(', ');

interface FullPagePortalProps {
  anchorEl?:HTMLElement | null;
  // Editor variables the content relies on, which the portal leaves behind.
  carriedVariables?:string[];
  children:React.ReactNode;
}

export const FullPagePortal = ({ anchorEl, carriedVariables = [], children }:FullPagePortalProps) => createPortal(
  <StyleSheetManager target={document.head}>
    <div
      data-color-scheme={colorSchemeOf(anchorEl)}
      style={{
        '--bn-font-family': fontFamilyOf(anchorEl),
        ...variablesOf(anchorEl, carriedVariables),
      } as React.CSSProperties}
    >
      {children}
    </div>
  </StyleSheetManager>,
  document.body
);

function colorSchemeOf(anchorEl?:HTMLElement | null):string | undefined {
  return anchorEl?.closest('[data-color-scheme]')?.getAttribute('data-color-scheme') ?? undefined;
}

// BlockNote declares its font on ".bn-root", which the portal leaves behind.
function fontFamilyOf(anchorEl?:HTMLElement | null):string | undefined {
  if (!anchorEl) return undefined;
  return getComputedStyle(anchorEl).getPropertyValue('--bn-font-family').trim() || undefined;
}

function variablesOf(anchorEl:HTMLElement | null | undefined, names:string[]):Record<string, string> {
  if (!anchorEl || names.length === 0) return {};
  const style = getComputedStyle(anchorEl);
  const carried:Record<string, string> = {};
  for (const name of names) {
    const value = style.getPropertyValue(name).trim();
    if (value) carried[name] = value;
  }
  return carried;
}

// Only the body has to be held: the modal is portalled out of the editor, so
// nothing the editor scrolls is an ancestor of it any more.
export function usePageScrollLock():void {
  useEffect(() => {
    const { style } = document.body;
    const previous = { overflow: style.overflow, paddingRight: style.paddingRight };
    // Room the scrollbar leaves behind, so the page does not jump sideways.
    const scrollbar = window.innerWidth - document.documentElement.clientWidth;

    style.overflow = 'hidden';
    if (scrollbar > 0) style.paddingRight = `${scrollbar}px`;

    return () => {
      style.overflow = previous.overflow;
      style.paddingRight = previous.paddingRight;
    };
  }, []);
}

export function keepFocusInside(panel:HTMLElement | null, event:React.KeyboardEvent):void {
  if (!panel) return;

  const focusable = Array.from(panel.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR))
    .filter((element) => element.offsetParent !== null);
  if (focusable.length === 0) return;

  const first = focusable[0];
  const last = focusable[focusable.length - 1];
  const root = panel.getRootNode() as Document | ShadowRoot;

  if (event.shiftKey && root.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && root.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}
