import type { BlockNoteEditor, InlineContentFromConfig } from "@blocknote/core";
import { LinkIcon } from "@primer/octicons-react";
import i18n from "../services/i18n.ts";
import { getAliases } from "../services/slashMenuAliases";
import { registerInlineWpCallbacks, clearInlineWpCallbacks } from "./InlineWorkPackageSpec";

type AnyEditor = BlockNoteEditor<any, any, any>;

function getCurrentBlockContent(editor: AnyEditor): {
  blockId: string;
  content: InlineContentFromConfig<any, any>[];
} | null {
  const cursor = editor.getTextCursorPosition();
  if (!cursor?.block) return null;
  const block = cursor.block as { id: string; content: InlineContentFromConfig<any, any>[] };
  return { blockId: block.id, content: block.content ?? [] };
}

function handleInlineWorkPackageClick(editor: AnyEditor): void {
  const key = `wp-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const pendingWpid = `pending:${key}`;
  // Generate a stable instanceId for this chip — used for event routing
  const instanceId = `iid-${Date.now()}-${Math.random().toString(36).slice(2)}`;

  const onSelect = (wpid: number): void => {
    const current = getCurrentBlockContent(editor);
    if (!current) return;

    const updatedContent = current.content.map((node) => {
      const n = node as { type: string; props?: { wpid?: string; instanceId?: string } };
      if (n.type === "inlineWorkPackage" && n.props?.wpid === pendingWpid) {
        return { ...n, props: { ...n.props, wpid: String(wpid), instanceId } };
      }
      return node;
    });

    editor.updateBlock(current.blockId, { content: updatedContent } as any);

    const blockId = current.blockId;
    requestAnimationFrame(() => {
      editor.focus();
      editor.setTextCursorPosition(blockId, "end");
    });
  };

  const onCancel = (): void => {
    const current = getCurrentBlockContent(editor);
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