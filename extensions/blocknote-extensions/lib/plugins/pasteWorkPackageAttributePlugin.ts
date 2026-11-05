import { Plugin, PluginKey } from 'prosemirror-state';
import type { Node } from 'prosemirror-model';
import { isStyledTextInlineContent } from '@blocknote/core';
import type { StyleSchema, StyledText } from '@blocknote/core';
import type { AnyEditor } from '../editorTypes';
import { splitAttributeMacros, type AttributeMacro } from '../components/WorkPackageAttribute/macros';
import { resolveAttributeMacro } from '../components/WorkPackageAttribute/resolveMacro';
import type { AttributeChoice } from '../components/WorkPackageAttribute/types';
import { canBlockWorkPackageReplaceCurrentBlock } from '../utils/blockContent';
import { moveCursorAfterBlock } from '../utils/cursor';
import { BLOCK_WP_ATTRIBUTE_TYPE, INLINE_WP_ATTRIBUTE_TYPE } from '../utils/nodeTypes';
import { isBlankText, pastedInlineContent, singlePastedTextblock, type AnyInline } from '../utils/pastedContent';

interface MacroPart { macro:AttributeMacro; text:StyledText<StyleSchema> }

type PastePart = MacroPart | { keep:AnyInline };

function isMacroPart(part:PastePart):part is MacroPart {
  return 'macro' in part;
}

/**
 * Turns pasted attribute macros (`workPackageValue:58:assignee`), as CKEditor
 * copies them, into work package attributes. Macros that cannot be resolved
 * stay text.
 */
export const pasteWorkPackageAttributePluginKey = new PluginKey('pasteWorkPackageAttribute');

export function pasteWorkPackageAttributePlugin(editor:AnyEditor):Plugin {
  return new Plugin({
    key: pasteWorkPackageAttributePluginKey,

    props: {
      handlePaste(_view, _event, slice) {
        if (!(INLINE_WP_ATTRIBUTE_TYPE in editor.schema.inlineContentSpecs)) return false;

        const pasted = singlePastedTextblock(slice.content);
        if (!pasted) return false;

        const parts = pasteParts(editor, pasted);
        if (!parts.some(isMacroPart)) return false;

        const block = editor.getTextCursorPosition()?.block;
        if (!block || block.type === 'codeBlock') return false;

        void insertAttributes(editor, parts);
        return true;
      },
    },
  });
}

function pasteParts(editor:AnyEditor, node:Node):PastePart[] {
  return pastedInlineContent(editor, node).flatMap((item):PastePart[] => {
    if (!isStyledTextInlineContent(item)) return [{ keep: item }];

    return splitAttributeMacros(item.text).map((segment) => (
      typeof segment === 'string'
        ? { keep: { ...item, text: segment } }
        : { macro: segment, text: item }
    ));
  });
}

async function insertAttributes(editor:AnyEditor, parts:PastePart[]):Promise<void> {
  const resolved = await Promise.all(
    parts.map((part) => (isMacroPart(part) ? resolveAttributeMacro(part.macro) : Promise.resolve(null)))
  );

  const inline:AnyInline[] = [];
  const blocks:AttributeChoice[] = [];
  let endsWithAttribute = false;

  parts.forEach((part, index) => {
    const attribute = resolved[index];
    if (attribute?.kind === 'block') {
      blocks.push(attribute.choice);
      return;
    }

    endsWithAttribute = attribute !== null;
    if (attribute) inline.push({ type: INLINE_WP_ATTRIBUTE_TYPE, props: attribute.choice, content: undefined });
    else if (isMacroPart(part)) inline.push({ ...part.text, text: part.macro.source });
    else inline.push(part.keep);
  });

  const hasVisibleInline = inline.some((item) => !isBlankText(item));
  if (hasVisibleInline && endsWithAttribute) inline.push({ type: 'text', text: ' ', styles: {} });

  editor.transact(() => {
    if (hasVisibleInline) editor.insertInlineContent(inline);
    if (blocks.length > 0) insertAttributeBlocks(editor, blocks);
  });
}

// A long text takes the place of an empty line, or follows the line it was pasted into.
function insertAttributeBlocks(editor:AnyEditor, choices:AttributeChoice[]):void {
  const line = editor.getTextCursorPosition().block;
  const blocks = choices.map((props) => ({ type: BLOCK_WP_ATTRIBUTE_TYPE, props })) as Parameters<typeof editor.insertBlocks>[0];

  const inserted = canBlockWorkPackageReplaceCurrentBlock(editor)
    ? editor.replaceBlocks([line], blocks).insertedBlocks
    : editor.insertBlocks(blocks, line, 'after');

  moveCursorAfterBlock(editor, inserted[inserted.length - 1].id);
}
