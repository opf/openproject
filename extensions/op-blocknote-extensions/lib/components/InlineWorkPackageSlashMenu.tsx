import type { BlockNoteEditor, InlineContentFromConfig } from "@blocknote/core";
import { LinkIcon } from "@primer/octicons-react";
import i18n from "../services/i18n.ts";
import { getAliases } from "../services/slashMenuAliases";
import { registerInlineWpCallbacks, clearInlineWpCallbacks } from "./InlineWorkPackage";

type AnyEditor = BlockNoteEditor<any, any, any>;

function handleInlineWorkPackageClick(editor: AnyEditor): void {
  const key = `wp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const pendingWpid = `pending:${key}`;
  const instanceId = `iid-${Date.now()}-${Math.random().toString(36).slice(2)}`;

  // Capture blockId before insertion — cursor may move later
  const insertedBlockId = editor.getTextCursorPosition()?.block?.id as string | undefined;

  const getBlockContent = (): { blockId: string; content: InlineContentFromConfig<any, any>[] } | null => {
    if (!insertedBlockId) return null;
    const block = editor.getBlock(insertedBlockId) as { id: string; content: InlineContentFromConfig<any, any>[] } | null;
    if (!block) return null;
    return { blockId: block.id, content: block.content ?? [] };
  };

  const onSelect = (wpid: number): void => {
    const current = getBlockContent();
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

  const onCancel = (): void => {
    const current = getBlockContent();
    if (!current) return;

    const updatedContent = current.content.filter((node) => {
      const n = node as { type: string; props?: { wpid?: string } };
      return !(n.type === "inlineWorkPackage" && n.props?.wpid === pendingWpid);
    });
    editor.updateBlock(current.blockId, { content: updatedContent } as any);
    clearInlineWpCallbacks(key);
  };

  registerInlineWpCallbacks(key, onSelect, onCancel);

  try {
    (editor.insertInlineContent as (content: unknown[]) => void)([
      { type: "inlineWorkPackage", props: { wpid: pendingWpid, instanceId, size: "s" } },
      " ",
    ]);
  } catch (e) {
    console.error("[inline-wp] insertInlineContent failed:", e);
    clearInlineWpCallbacks(key);
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