// @vitest-environment jsdom
import { describe, it, expect, vi } from "vitest";
import { BlockNoteEditor } from "@blocknote/core";
import {
  getSizeFromCurrentBlock,
  insertWpChipIntoBlock,
  clearTriggerText,
} from "../../../lib/components/HashMenu/editorUtils";

function createTestEditor(text: string) {
  const editor = BlockNoteEditor.create({
    initialContent: [{ type: "paragraph", content: text }],
  });
  
  const block = editor.document[0];
  editor.setTextCursorPosition(block, "end");
  
  return editor;
}

describe("getSizeFromCurrentBlock", () => {
  it("returns xxs for #", () => {
    const editor = createTestEditor("#foo");
    expect(getSizeFromCurrentBlock(editor as any)).toBe("xxs");
  });

  it("returns xs for ##", () => {
    const editor = createTestEditor("##foo");
    expect(getSizeFromCurrentBlock(editor as any)).toBe("xs");
  });

  it("returns s for ### or more", () => {
    const editor = createTestEditor("###foo");
    expect(getSizeFromCurrentBlock(editor as any)).toBe("s");

    const editor2 = createTestEditor("####foo");
    expect(getSizeFromCurrentBlock(editor2 as any)).toBe("s");
  });

  it("returns xxs if no hashes", () => {
    const editor = createTestEditor("foo");
    expect(getSizeFromCurrentBlock(editor as any)).toBe("xxs");
  });
});

describe("clearTriggerText", () => {
  it("removes # text and returns block id", () => {
    const editor = createTestEditor("#foo");
    const blockId = clearTriggerText(editor as any);
    
    expect(blockId).toBe(editor.document[0].id);
    const block = editor.getBlock(editor.document[0].id);
    expect(block?.content).toEqual([]); 
  });

  it("does nothing if no block", () => {
    const editor = {
      _tiptapEditor: null,
      getTextCursorPosition: () => null,
      updateBlock: vi.fn(),
    };
    expect(clearTriggerText(editor as any)).toBeNull();
  });

  it("keeps text before # and removes trigger", () => {
    const editor = createTestEditor("Hello #foo");
    const blockId = clearTriggerText(editor as any);
    
    expect(blockId).toBe(editor.document[0].id);
    const block = editor.getBlock(editor.document[0].id);
    expect((block?.content as any)[0].text).toBe("Hello ");
  });

  it("works with multiple # in the text", () => {
    const editor = createTestEditor("Pre #one #two #three");
    const blockId = clearTriggerText(editor as any);
    
    expect(blockId).toBe(editor.document[0].id);
    const block = editor.getBlock(editor.document[0].id);
    
    expect((block?.content as any)[0].text).toBe("Pre #one #two ");
  });
});

describe("insertWpChipIntoBlock", () => {
  it("adds a chip to the block content", () => {
    const editor = createTestEditor("test");
    
    const insertSpy = vi.spyOn(editor, "insertInlineContent").mockImplementation(() => {});
    vi.spyOn(editor, "focus").mockImplementation(() => {});

    insertWpChipIntoBlock(
      editor as any,
      editor.document[0].id,
      { id: 1, subject: "Fix bug" } as any,
      "xxs"
    );

    expect(insertSpy).toHaveBeenCalledWith([
      {
        type: "openProjectWorkPackageInline",
        props: { wpid: "1", instanceId: expect.any(String), size: "xxs" },
      },
      { type: "text", text: " ", styles: {} },
    ]);
  });
});