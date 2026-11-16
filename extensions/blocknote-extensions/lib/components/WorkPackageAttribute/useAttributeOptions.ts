import { useCallback, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import type { BlockNoteEditor } from '@blocknote/core';
import { useTapActivation } from '../../utils/tapActivation';
import { isKeyboardClick } from '../../utils/a11y';
import { useOptionsMenu } from '../../hooks/useOptionsMenu';
import { useOptionsHost } from '../../utils/optionsHost';
import { useSuppressFormattingToolbar } from '../../hooks/useSuppressFormattingToolbar';
import { usePressOutside } from '../../hooks/usePressOutside';
import { useSelectionAnnouncement } from '../../hooks/useSelectionAnnouncement';
import { formatWorkPackageId } from '../../utils/id';
import { normalizeDisplay, type AttributeDisplay } from './display';
import type { ResolvedAttribute } from './useWorkPackageAttribute';
import { attributeIdentity } from './WorkPackageAttributeView';
import type { AttributeProps } from './types';

interface AttributeOptionsSettings {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  editor?:BlockNoteEditor<any, any, any>;
  content:AttributeProps;
  resolved:ResolvedAttribute;
  onDisplayChange?:(display:AttributeDisplay) => void;
  onActivate?:() => void;
}

export function useAttributeOptions({ editor, content, resolved, onDisplayChange, onActivate }:AttributeOptionsSettings) {
  const { t } = useTranslation();
  const elementRef = useRef<HTMLElement | null>(null);
  const options = useOptionsMenu();
  const tapProps = useTapActivation();
  useSuppressFormattingToolbar(editor, options.isOpen);
  usePressOutside(elementRef, options.isOpen, options.close);

  const optionsHostRef = useOptionsHost(() => {
    if (editor && !editor.isEditable) return;
    options.open(true);
  });
  const setElementRef = useCallback((element:HTMLElement | null) => {
    elementRef.current = element;
    optionsHostRef(element);
  }, [optionsHostRef]);

  const { workPackageId, attributeName } = attributeIdentity(resolved, content.displayId, content.attribute);
  useSelectionAnnouncement(
    elementRef,
    editor,
    t('workPackageAttribute.options.selectedDescription', { attribute: attributeName, id: formatWorkPackageId(workPackageId) }),
  );

  const active = normalizeDisplay(content.display);

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

  return { elementRef, setElementRef, options, active, pick, toggleProps };
}
