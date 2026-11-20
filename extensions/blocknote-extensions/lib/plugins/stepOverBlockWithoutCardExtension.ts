import { createExtension } from '@blocknote/core';
import { NodeSelection, Plugin, PluginKey, Selection } from 'prosemirror-state';
import { pendingBlockRegistry } from '../components/BlockWorkPackage/pendingBlockRegistry';
import { BLOCK_WP_TYPE } from '../utils/nodeTypes';

// A work package block without a work package renders nothing unless this client is the one
// choosing it. Node-selected, it hides the caret and swallows typing (BNE-181).
function isBlockWithoutCard(selection:NodeSelection):boolean {
  if (selection.node.type.name !== BLOCK_WP_TYPE || selection.node.attrs.wpid) return false;

  const blockId = (selection.$from.parent.attrs as { id?:string }).id;
  return blockId === undefined || !pendingBlockRegistry.has(blockId);
}

const stepOverBlockWithoutCardPlugin = new Plugin({
  key: new PluginKey('stepOverBlockWithoutCard'),

  appendTransaction(_transactions, oldState, newState) {
    const { selection } = newState;
    if (!(selection instanceof NodeSelection) || selection.eq(oldState.selection)) return null;
    if (!isBlockWithoutCard(selection)) return null;

    const forward = selection.from >= oldState.selection.from;
    const target = forward
      ? Selection.findFrom(newState.doc.resolve(selection.to), 1)
      : Selection.findFrom(newState.doc.resolve(selection.from), -1);

    return target ? newState.tr.setSelection(target) : null;
  },
});

export const StepOverBlockWithoutCardExtension = createExtension(() => ({
  key: 'stepOverBlockWithoutCard',
  prosemirrorPlugins: [stepOverBlockWithoutCardPlugin],
}))();
