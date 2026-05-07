import { useBlockNoteEditor } from "@blocknote/react";
import { InlineWorkPackageChip } from "./InlineWorkPackageChip";
import type { InlineWorkPackageChipProps } from "./InlineWorkPackageChip";

export const InlineWorkPackageChipInEditor = (props: InlineWorkPackageChipProps) => {
  const editor = useBlockNoteEditor();

  const handleDragStart = () => {
    const selectedText = editor.getSelectedText();
    if (!selectedText || selectedText.length === 0) return;

    window.getSelection()?.removeAllRanges();

    const cursor = editor.getTextCursorPosition();
    if (cursor?.block) {
      editor.setTextCursorPosition(cursor.block.id, "end");
    }
  };

  return <InlineWorkPackageChip {...props} onDragStart={handleDragStart} />;
};