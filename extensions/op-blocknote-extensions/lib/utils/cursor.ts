import type { BlockNoteEditor } from "@blocknote/core";
import { TextSelection } from "prosemirror-state";

type AnyEditor = BlockNoteEditor<any, any, any>;

export function moveCursorAfterBlock(editor: AnyEditor, blockId: string): void {
  editor.focus();
  editor.setTextCursorPosition(blockId, "end");

  const cursor = editor.getTextCursorPosition();
  if (!cursor?.nextBlock && cursor?.block) {
    editor.insertBlocks([{ type: "paragraph", content: [] }], cursor.block.id, "after");
  }

  const updated = editor.getTextCursorPosition();
  if (updated?.nextBlock) {
    editor.setTextCursorPosition(updated.nextBlock.id, "start");
  }
}

export function placeCursorAfterInlineNode(editor: AnyEditor, instanceId: string): void {
  const { doc } = editor.prosemirrorState;
  let targetPos: number | null = null;

  doc.descendants((node, pos) => {
    if (targetPos !== null) return false;
    if ((node.attrs as Record<string, unknown>)?.instanceId === instanceId) {
      targetPos = pos + node.nodeSize;
      return false;
    }
    return true;
  });

  if (targetPos !== null) {
    const pos = targetPos;
    editor.transact((tr) => {
      tr.setSelection(TextSelection.create(tr.doc, pos));
    });
  }
}
