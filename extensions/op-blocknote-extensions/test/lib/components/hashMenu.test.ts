// @vitest-environment jsdom
import { describe, it, expect, vi } from "vitest";
import {
  getSizeFromCurrentBlock,
  insertWpChipIntoBlock,
  clearTriggerText,
} from "../../../lib/components/HashMenu/editorUtils";

type FakeContent = { type: string; text?: string; styles?: any; props?: any }[];

function findCursorPos(fullText: string): number {
  const match = fullText.match(/#+/);
  if (!match || match.index === undefined) return fullText.length;
  return match.index + match[0].length;
}

function makeFakeTiptap(block: { id: string; content: FakeContent }) {
  const getFullText = () =>
    block.content
      .filter((n) => n.type === "text")
      .map((n) => n.text ?? "")
      .join("");

  return {
    get state() {
      const fullText = getFullText();
      const cursorPos = findCursorPos(fullText);

      return {
        selection: {
          from: cursorPos,
          $from: {
            parentOffset: cursorPos,
            parent: {
              textBetween(start: number, end: number) {
                const text = getFullText();
                const absStart = Math.max(0, cursorPos - (end - start));
                return text.slice(absStart, cursorPos);
              },
            },
          },
        },
        tr: {
          delete(start: number, end: number) {
            return { _start: start, _end: end };
          },
        },
      };
    },
    view: {
      dispatch(tr: { _start: number; _end: number }) {
        const fullText = getFullText();
        const hashIndex = fullText.search(/#+/);
        const newText = hashIndex <= 0 ? "" : fullText.slice(0, hashIndex);

        if (newText === "") {
          block.content = [];
        } else {
          const firstTextNode = block.content.find((n) => n.type === "text");
          const nonTextNodes = block.content.filter((n) => n.type !== "text");
          block.content = [
            ...(firstTextNode ? [{ ...firstTextNode, text: newText }] : []),
            ...nonTextNodes,
          ];
        }
      },
    },
  };
}

function makeFakeEditor(content: FakeContent = []) {
  const block = { id: "block-1", content: [...content] };
  const inserted: FakeContent = [];

  const editor: any = {
    block,
    inserted,
    getTextCursorPosition: () => ({ block }),
    getBlock: (id: string) => (id === block.id ? block : null),
    updateBlock: (id: string, update: { content: FakeContent }) => {
      if (id === block.id) block.content = update.content;
    },
    insertInlineContent: (content: FakeContent) => {
      inserted.push(...content);
    },
    focus: vi.fn(),
    setTextCursorPosition: vi.fn(),
  };

  editor._tiptapEditor = makeFakeTiptap(block);

  return editor;
}

describe("getSizeFromCurrentBlock", () => {
  it("returns xxs for #", () => {
    const editor = makeFakeEditor([{ type: "text", text: "#foo" }]);
    expect(getSizeFromCurrentBlock(editor as any)).toBe("xxs");
  });

  it("returns xs for ##", () => {
    const editor = makeFakeEditor([{ type: "text", text: "##foo" }]);
    expect(getSizeFromCurrentBlock(editor as any)).toBe("xs");
  });

  it("returns s for ### or more", () => {
    const editor = makeFakeEditor([{ type: "text", text: "###foo" }]);
    expect(getSizeFromCurrentBlock(editor as any)).toBe("s");

    const editor2 = makeFakeEditor([{ type: "text", text: "####foo" }]);
    expect(getSizeFromCurrentBlock(editor2 as any)).toBe("s");
  });

  it("returns xxs if no hashes", () => {
    const editor = makeFakeEditor([{ type: "text", text: "foo" }]);
    expect(getSizeFromCurrentBlock(editor as any)).toBe("xxs");
  });
});

describe("clearTriggerText", () => {
  it("removes # text and returns block id", () => {
    const editor = makeFakeEditor([{ type: "text", text: "#foo" }]);
    const blockId = clearTriggerText(editor as any);
    expect(blockId).toBe("block-1");
    expect(editor.block.content).toEqual([]);
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
    const editor = makeFakeEditor([{ type: "text", text: "Hello #foo" }]);
    const blockId = clearTriggerText(editor as any);
    expect(blockId).toBe("block-1");
    expect(editor.block.content).toEqual([{ type: "text", text: "Hello " }]);
  });

  it("works with multiple # in the text", () => {
    const editor = makeFakeEditor([{ type: "text", text: "Pre #one #two #three" }]);
    const blockId = clearTriggerText(editor as any);
    expect(blockId).toBe("block-1");
    expect(editor.block.content).toEqual([{ type: "text", text: "Pre " }]);
  });
});

describe("insertWpChipIntoBlock", () => {
  it("adds a chip to the block content", () => {
    const editor = makeFakeEditor([]);
    insertWpChipIntoBlock(
      editor as any,
      "block-1",
      { id: 1, subject: "Fix bug" } as any,
      "xxs"
    );

    const inserted = editor.inserted;
    expect(inserted.length).toBe(2);

    const chip = inserted.find(
      (item: any): item is { type: string; props: { size: string } } =>
        item.type === "openProjectWorkPackageInline" && item.props?.size
    );
    expect(chip).toBeDefined();
    expect(chip?.props.size).toBe("xxs");
  });

  it("does nothing if block not found", () => {
    const editor = makeFakeEditor([]);
    expect(() =>
      insertWpChipIntoBlock(editor as any, "wrong-id", { id: 1 } as any, "xxs")
    ).not.toThrow();
  });
});