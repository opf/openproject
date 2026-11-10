import { useRef } from 'react';
import type { BlockNoteEditor } from '@blocknote/core';
import { useTapActivation } from '../../utils/tapActivation';
import { isKeyboardClick } from '../../utils/a11y';
import { useOptionsMenu } from '../../hooks/useOptionsMenu';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { usePressOutside } from '../../hooks/usePressOutside';
import { normalizeDisplay, type AttributeDisplay } from './display';

interface AttributeOptionsSettings {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  display:string;
  onDisplayChange?:(display:AttributeDisplay) => void;
  onActivate?:() => void;
}

export function useAttributeOptions({ editor, display, onDisplayChange, onActivate }:AttributeOptionsSettings) {
  const elementRef = useRef<HTMLElement | null>(null);
  const options = useOptionsMenu();
  const tapProps = useTapActivation();
  useSuppressFormattingToolbar(editor, options.isOpen);
  usePressOutside(elementRef, options.isOpen, options.close);

  const active = normalizeDisplay(display);

  const toggleProps = tapProps((event) => {
    // Links in a long text keep doing what links do, and a read-only document stays as it is.
    if (event?.target instanceof Element && event.target.closest('a')) return;
    if (editor && !editor.isEditable) return;
    event?.preventDefault();
    event?.stopPropagation();
    onActivate?.();
    options.toggle(isKeyboardClick(event));
  });

  const pick = (picked:AttributeDisplay) => {
    if (picked !== active) onDisplayChange?.(picked);
  };

  return { elementRef, options, active, pick, toggleProps };
}
