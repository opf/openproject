import type { BlockNoteEditor, InlineContentFromConfig } from "@blocknote/core";
import { LinkIcon } from "@primer/octicons-react";
import i18n from "../services/i18n.ts";
import { getAliases } from "../services/slashMenuAliases";
import { registerInlineWpCallbacks, clearInlineWpCallbacks } from "./InlineWorkPackage";
import { makeInstanceId } from "../services/utils";

type AnyEditor = BlockNoteEditor<any, any, any>;
type AnyInlineNode = InlineContentFromConfig<any, any>;

// Returns the current content of the block where the chip was inserted.
function getBlockContent(
  editor: AnyEditor,
  blockId: string
): { blockId: string; content: AnyInlineNode[] } | null {
  const block = editor.getBlock(blockId) as { id: string; content: AnyInlineNode[] } | null;
  if (!block) return null;
  return { blockId: block.id, content: block.content ?? [] };
}

// Replaces the pending chip with the real wpid after the user selects a work package.
// Also ensures there is a space node after the chip so the cursor has somewhere to land.

function buildOnSelect(
  editor: AnyEditor,
  blockId: string,
  pendingWpid: string,
  instanceId: string
): (wpid: number) => void {
  return (wpid: number) => {
    const current = getBlockContent(editor, blockId);
    if (!current) return;

    const chipIndex = current.content.findIndex((node) => {
      const n = node as { type: string; props?: { wpid?: string } };
      return n.type === "inlineWorkPackage" && n.props?.wpid === pendingWpid;
    });

    const updatedContent = current.content.map((node) => {
      const n = node as { type: string; props?: { wpid?: string; instanceId?: string } };
      if (n.type === "inlineWorkPackage" && n.props?.wpid === pendingWpid) {
        return { ...n, props: { ...n.props, wpid: String(wpid), instanceId } };
      }
      return node;
    });

    const nodeAfter = updatedContent[chipIndex + 1] as any;
    const hasSpaceAfter = nodeAfter?.type === "text" && nodeAfter?.text?.startsWith(" ");
    if (!hasSpaceAfter) {
      updatedContent.splice(chipIndex + 1, 0, { type: "text", text: " ", styles: {} } as any);
    }

    editor.updateBlock(current.blockId, { content: updatedContent } as any);

    requestAnimationFrame(() => {
      editor.focus();
      editor.setTextCursorPosition(current.blockId, "end");
    });
  };
}

// Removes the pending chip from the document when the user cancels the search
function buildOnCancel(
  editor: AnyEditor,
  blockId: string,
  pendingWpid: string,
  instanceId: string
): () => void {
  return () => {
    const current = getBlockContent(editor, blockId);
    if (!current) return;

    const updatedContent = current.content.filter((node) => {
      const n = node as { type: string; props?: { wpid?: string } };
      return !(n.type === "inlineWorkPackage" && n.props?.wpid === pendingWpid);
    });

    editor.updateBlock(current.blockId, { content: updatedContent } as any);
    clearInlineWpCallbacks(instanceId);
  };
}


// Inserts a pending inline chip at the current cursor position and registers
// its select/cancel callbacks so the search popover can resolve them.

function handleInlineWorkPackageClick(editor: AnyEditor): void {
  const instanceId = makeInstanceId();
  const pendingWpid = `pending:${instanceId}`;

  // Capture the block ID before insertion — the cursor may move afterwards.
  const blockId = editor.getTextCursorPosition()?.block?.id as string | undefined;
  if (!blockId) return;

  const onSelect = buildOnSelect(editor, blockId, pendingWpid, instanceId);
  const onCancel = buildOnCancel(editor, blockId, pendingWpid, instanceId);

  registerInlineWpCallbacks(instanceId, onSelect, onCancel);

  try {
    (editor.insertInlineContent as (content: unknown[]) => void)([
      { type: "inlineWorkPackage", props: { wpid: pendingWpid, instanceId, size: "s" } },
      " ",
    ]);
  } catch (e) {
    console.error("[inline-wp] insertInlineContent failed:", e);
    clearInlineWpCallbacks(instanceId);
  }
}

export const inlineWorkPackageSlashMenu = (editor: BlockNoteEditor<any, any, any>) => ({
  title: i18n.t("slashMenu.title"),
  onItemClick: () => handleInlineWorkPackageClick(editor),
  aliases: [...getAliases()],
  group: "OpenProject",
  icon: <LinkIcon size={18} />,
  subtext: i18n.t("slashMenu.subtext"),
});