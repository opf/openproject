import { createExtension } from '@blocknote/core';
import { TextSelection } from 'prosemirror-state';
import type { AnyEditor } from '../editorTypes';
import { selectedWorkPackageDom } from '../utils/selection';
import { openOptionsWithin } from '../utils/optionsHost';
import { selectInlineChipAt } from '../utils/inlineChipActions';
import { INLINE_WP_TYPE } from '../utils/nodeTypes';

// Kept out of the tab order, a work package is operated through the editor
// itself: the arrow keys select it and Enter or Space opens its options. A
// NodeSelection tells a screen reader nothing, so it is announced instead.

function createLiveRegion(ownerDocument:Document):HTMLElement {
  const region = ownerDocument.createElement('div');
  region.setAttribute('role', 'status');
  region.className = 'op-bn-live-region';
  Object.assign(region.style, {
    position: 'absolute',
    width: '1px',
    height: '1px',
    overflow: 'hidden',
    clipPath: 'inset(50%)',
    whiteSpace: 'nowrap',
  });
  return region;
}

// BlockNote makes inline content without content unselectable, so the caret
// would otherwise step over a chip without ever selecting it.
function selectChipBeside(editor:AnyEditor, side:'before' | 'after'):boolean {
  const { selection } = editor.prosemirrorState;
  if (!(selection instanceof TextSelection) || !selection.$cursor) return false;

  const { $cursor } = selection;
  const chip = side === 'before' ? $cursor.nodeBefore : $cursor.nodeAfter;
  if (chip?.type.name !== INLINE_WP_TYPE) return false;

  selectInlineChipAt(editor, side === 'before' ? $cursor.pos - chip.nodeSize : $cursor.pos);
  return true;
}

// Swallowed whenever a work package is selected: let through, the key would
// replace it with a line break or a space.
function openSelectedOptions(editor:AnyEditor):boolean {
  const dom = selectedWorkPackageDom(editor);
  if (!dom) return false;

  openOptionsWithin(dom);
  return true;
}

// BlockNote shows its formatting toolbar for any selection that is not empty,
// though there is nothing to format on a work package.
function keepFormattingToolbarClosed(editor:AnyEditor):(() => void) | undefined {
  const store = editor.getExtension('formattingToolbar')?.store;

  return store?.subscribe(() => {
    if (store.state && selectedWorkPackageDom(editor)) store.setState(false);
  });
}

export const WorkPackageAccessibilityExtension = createExtension(({ editor }:{ editor:AnyEditor }) => {
  let liveRegion:HTMLElement | null = null;
  let pendingAnnouncement = 0;

  const clearAnnouncement = () => {
    cancelAnimationFrame(pendingAnnouncement);
    if (liveRegion) liveRegion.textContent = '';
  };

  // Emptied first, so that selecting the same work package again is announced again.
  const announce = (message:string) => {
    clearAnnouncement();
    pendingAnnouncement = requestAnimationFrame(() => {
      if (liveRegion) liveRegion.textContent = message;
    });
  };

  return {
    key: 'workPackageAccessibility',

    mount: ({ dom, signal }) => {
      const region = createLiveRegion(dom.ownerDocument);
      dom.after(region);
      liveRegion = region;

      const releaseFormattingToolbar = keepFormattingToolbarClosed(editor);

      signal.addEventListener('abort', () => {
        releaseFormattingToolbar?.();
        clearAnnouncement();
        region.remove();
        liveRegion = null;
      });
    },

    keyboardShortcuts: {
      ArrowLeft: () => selectChipBeside(editor, 'before'),
      ArrowRight: () => selectChipBeside(editor, 'after'),
      Enter: () => openSelectedOptions(editor),
      Space: () => openSelectedOptions(editor),
    },

    announce,
    clearAnnouncement,
  };
});
