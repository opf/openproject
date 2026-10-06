import { useRef, useState } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { useTapActivation } from '../../utils/tapActivation';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { usePressOutside } from '../../hooks/usePressOutside';
import { normalizeDisplay, type AttributeDisplay } from './externalHtml';

interface AttributeDisplayMenuOptions {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  display:string;
  onDisplayChange?:(display:AttributeDisplay) => void;
  onActivate?:() => void;
}

export function useAttributeDisplayMenu({ editor, display, onDisplayChange, onActivate }:AttributeDisplayMenuOptions) {
  const elementRef = useRef<HTMLElement | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const tapProps = useTapActivation();
  useSuppressFormattingToolbar(editor, menuOpen);
  usePressOutside(elementRef, menuOpen, () => setMenuOpen(false));

  const active = normalizeDisplay(display);

  const toggleProps = tapProps((event) => {
    // Links in a long text keep doing what links do, and a read-only document stays as it is.
    if (event?.target instanceof Element && event.target.closest('a')) return;
    if (editor && !editor.isEditable) return;
    event?.preventDefault();
    event?.stopPropagation();
    onActivate?.();
    setMenuOpen((open) => !open);
  });

  const pick = (picked:AttributeDisplay) => {
    setMenuOpen(false);
    if (picked !== active) onDisplayChange?.(picked);
  };

  return { elementRef, menuOpen, active, pick, toggleProps };
}
