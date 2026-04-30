import { useBlockNoteEditor } from "@blocknote/react";
import { useDragSelection } from "../../hooks/useDragSelection";
import { InlineWorkPackageChip } from "./InlineWorkPackageChip";
import type { InlineWorkPackageChipProps } from "./InlineWorkPackageChip";

export const InlineWorkPackageChipInEditor = (props: InlineWorkPackageChipProps) => {
  const editor = useBlockNoteEditor();
  const handleDragStart = useDragSelection(editor);

  return <InlineWorkPackageChip {...props} onDragStart={handleDragStart} />;
};