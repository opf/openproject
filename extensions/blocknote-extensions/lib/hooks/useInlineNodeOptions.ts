import type { RefObject } from 'react';
import type { AnyEditor } from '../editorTypes';
import { findInlineChipAtDOM, removeInlineChipAt, selectInlineChipAt } from '../utils/inlineChipActions';
import type { FoundInlineChip } from '../utils/inlineChipActions';
import { isKeyboardClick } from '../utils/a11y';
import { useTapActivation } from '../utils/tapActivation';
import type { TapActivationProps } from '../utils/tapActivation';
import { useOptionsMenu } from './useOptionsMenu';
import type { OptionsMenu } from './useOptionsMenu';
import { usePressOutside } from './usePressOutside';
import { useSuppressFormattingToolbar } from './useSuppressFormattingToolbar';

export interface InlineNodeOptions {
  options:OptionsMenu;
  // `beforeToggle` is for a caller with a popover of its own to close first.
  activationProps:(beforeToggle?:() => void) => TapActivationProps;
  findNode:() => FoundInlineChip | null;
  removeNode:() => void;
}

// The options popover of an atom inline node (work package chip, user mention):
// activating the node selects it and toggles the popover, a press outside closes it.
export function useInlineNodeOptions(
  editor:AnyEditor | undefined,
  nodeRef:RefObject<HTMLElement | null>,
  nodeType:string,
):InlineNodeOptions {
  const options = useOptionsMenu();

  useSuppressFormattingToolbar(editor, options.isOpen);
  usePressOutside(nodeRef, options.isOpen, options.close);

  const findNode = () => {
    if (!editor || !nodeRef.current) return null;
    return findInlineChipAtDOM(editor, nodeRef.current, nodeType);
  };

  const selectNode = () => {
    if (!editor) return;
    const found = findNode();
    if (found) selectInlineChipAt(editor, found.position, nodeType);
    editor.getExtension('formattingToolbar')?.store?.setState(false);
  };

  const removeNode = () => {
    const found = findNode();
    if (editor && found) removeInlineChipAt(editor, found.position, nodeType);
  };

  const tapProps = useTapActivation();
  const activationProps = (beforeToggle?:() => void) => tapProps((event) => {
    event?.preventDefault();
    event?.stopPropagation();
    beforeToggle?.();
    options.toggle(isKeyboardClick(event));
    selectNode();
  });

  return { options, activationProps, findNode, removeNode };
}
