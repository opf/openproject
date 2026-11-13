import { useEffect, type ReactNode, type RefObject } from 'react';
import { createPortal } from 'react-dom';
import { useTranslation } from 'react-i18next';
import { StyleSheetManager } from 'styled-components';
import { XIcon } from '@primer/octicons-react';
import { Header, HeaderTitle, IconButton, Overlay, Panel } from './atoms';

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

const FullPagePortal = ({ anchorEl, carriedVariables = [], children }:FullPagePortalProps) => createPortal(
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

function usePageScrollLock():void {
  useEffect(() => {
    const { style } = document.body;
    const previous = { overflow: style.overflow, paddingRight: style.paddingRight };
    const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;

    style.overflow = 'hidden';
    if (scrollbarWidth > 0) style.paddingRight = `${scrollbarWidth}px`;

    return () => {
      style.overflow = previous.overflow;
      style.paddingRight = previous.paddingRight;
    };
  }, []);
}

function keepFocusInside(panel:HTMLElement | null, event:React.KeyboardEvent):void {
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

interface ModalProps {
  anchorEl?:HTMLElement | null;
  carriedVariables?:string[];
  panelRef:RefObject<HTMLDivElement | null>;
  title:string;
  // Once something is filled in, only the buttons close it, so a stray click or Escape loses nothing.
  dismissible:boolean;
  onCancel:() => void;
  children:ReactNode;
}

export const Modal = ({
  anchorEl,
  carriedVariables,
  panelRef,
  title,
  dismissible,
  onCancel,
  children,
}:ModalProps) => {
  const { t } = useTranslation();
  usePageScrollLock();
  useEffect(() => { panelRef.current?.focus(); }, [panelRef]);

  const dismiss = () => {
    if (dismissible) onCancel();
  };

  return (
    <FullPagePortal anchorEl={anchorEl} carriedVariables={carriedVariables}>
      <Overlay onMouseDown={dismiss}>
        <Panel
          ref={panelRef}
          tabIndex={-1}
          aria-label={title}
          onMouseDown={(event) => event.stopPropagation()}
          onKeyDown={(event) => {
            event.stopPropagation();
            if (event.key === 'Escape') dismiss();
            if (event.key === 'Tab') keepFocusInside(panelRef.current, event);
          }}
        >
          <Header>
            <HeaderTitle>{title}</HeaderTitle>
            <IconButton type="button" aria-label={t('createWorkPackage.close')} onClick={onCancel}>
              <XIcon size={16} />
            </IconButton>
          </Header>
          {children}
        </Panel>
      </Overlay>
    </FullPagePortal>
  );
};
