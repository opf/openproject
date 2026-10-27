import { useCallback, useState } from 'react';
import type { RefObject } from 'react';
import type { AnyEditor } from '../editorTypes';
import { findInlineNodeAtDOM, removeInlineNodeAt, selectInlineNodeAt } from '../utils/inlineNodes';
import type { FoundInlineNode } from '../utils/inlineNodes';
import { useTapActivation } from '../utils/tapActivation';
import type { TapActivationProps } from '../utils/tapActivation';
import { usePressOutside } from './usePressOutside';
import { useSuppressFormattingToolbar } from './useSuppressFormattingToolbar';

export interface InlineNodeOptions {
  optionsOpen:boolean;
  closeOptions:() => void;
  // `beforeToggle` is for a caller with a popover of its own to close first.
  activationProps:(beforeToggle?:() => void) => TapActivationProps;
  findNode:() => FoundInlineNode | null;
  removeNode:() => void;
}

// The options popover of an atom inline node (work package chip, user mention):
// activating the node selects it and toggles the popover, a press outside closes it.
export function useInlineNodeOptions(
  editor:AnyEditor | undefined,
  nodeRef:RefObject<HTMLElement | null>,
  nodeType:string,
):InlineNodeOptions {
  const [optionsOpen, setOptionsOpen] = useState(false);
  const closeOptions = useCallback(() => setOptionsOpen(false), []);

  useSuppressFormattingToolbar(editor, optionsOpen);
  usePressOutside(nodeRef, optionsOpen, closeOptions);

  const findNode = () => {
    if (!editor || !nodeRef.current) return null;
    return findInlineNodeAtDOM(editor, nodeRef.current, nodeType);
  };

  const selectNode = () => {
    if (!editor) return;
    const found = findNode();
    if (found) selectInlineNodeAt(editor, found.position, nodeType);
    editor.getExtension('formattingToolbar')?.store?.setState(false);
  };

  const removeNode = () => {
    const found = findNode();
    if (editor && found) removeInlineNodeAt(editor, found.position, nodeType);
  };

  const tapProps = useTapActivation();
  const activationProps = (beforeToggle?:() => void) => tapProps((event) => {
    event?.preventDefault();
    event?.stopPropagation();
    beforeToggle?.();
    setOptionsOpen((open) => !open);
    selectNode();
  });

  return { optionsOpen, closeOptions, activationProps, findNode, removeNode };
}
