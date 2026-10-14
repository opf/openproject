//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { describe, expect, it } from "vitest";
import * as Y from "yjs";
import { createEditor, DOCUMENT_FRAGMENT } from "../../src/editor";
import {
  duplicateBlockIds,
  editOnto,
  normalizeBlocks,
  readBlocks,
  writeBlocks,
} from "../../src/services/documentContentService";

function firstBlock(doc: Y.Doc) {
  return (doc.getXmlFragment(DOCUMENT_FRAGMENT).firstChild as Y.XmlElement).firstChild;
}

function documentWith(blocks: Parameters<ReturnType<typeof createEditor>["blocksToYDoc"]>[0]) {
  return createEditor().blocksToYDoc(blocks, DOCUMENT_FRAGMENT);
}

describe("documentContentService", () => {
  it("normalizes partial blocks into BlockNote's canonical form", () => {
    const [block] = normalizeBlocks([{ type: "heading", content: "Title" }]);

    expect(block.id).toEqual(expect.any(String));
    expect(block).toMatchObject({
      type: "heading",
      props: { level: 1, textAlignment: "left" },
      content: [{ type: "text", text: "Title", styles: {} }],
      children: [],
    });
  });

  it("normalizes an empty document into a single empty paragraph", () => {
    expect(normalizeBlocks([])).toMatchObject([{ type: "paragraph", content: [] }]);
  });

  it("finds duplicate ids, including nested blocks", () => {
    expect(duplicateBlockIds([{ id: "a" }, { id: "b", children: [{ id: "a" }] }, {}])).toEqual(["a"]);
  });

  it("writes only the difference into the Yjs document", () => {
    const doc = documentWith([
      { id: "a", type: "paragraph", content: "Unchanged" },
      { id: "b", type: "paragraph", content: "Hello" },
    ]);
    const untouched = firstBlock(doc);
    const updates: Uint8Array[] = [];
    doc.on("update", (update: Uint8Array) => updates.push(update));

    const target = readBlocks(doc);
    target[1].content = [{ type: "text", text: "Hello world", styles: {} }];
    writeBlocks(doc, normalizeBlocks([...target, { id: "c", type: "paragraph", content: "New" }]));

    expect(readBlocks(doc).map(({ id, content }) => [id, content])).toEqual([
      ["a", [{ type: "text", text: "Unchanged", styles: {} }]],
      ["b", [{ type: "text", text: "Hello world", styles: {} }]],
      ["c", [{ type: "text", text: "New", styles: {} }]],
    ]);
    expect(firstBlock(doc)).toBe(untouched);
    expect(updates).toHaveLength(1);
  });

  it("produces updates that converge on other replicas", () => {
    const doc = documentWith([{ id: "a", type: "paragraph", content: "Hello" }]);
    const replica = new Y.Doc();
    Y.applyUpdate(replica, Y.encodeStateAsUpdate(doc));
    doc.on("update", (update: Uint8Array) => Y.applyUpdate(replica, update));

    writeBlocks(doc, normalizeBlocks([{ id: "a", type: "heading", content: "Hello" }]));

    expect(readBlocks(replica)).toEqual(readBlocks(doc));
    expect(readBlocks(replica)[0].type).toEqual("heading");
  });

  it("does not emit an update when nothing changed", () => {
    const doc = documentWith([{ id: "a", type: "paragraph", content: "Hello" }]);
    const updates: Uint8Array[] = [];
    doc.on("update", (update: Uint8Array) => updates.push(update));

    writeBlocks(doc, readBlocks(doc));

    expect(updates).toHaveLength(0);
  });

  describe("editOnto", () => {
    function contents(doc: Y.Doc) {
      return readBlocks(doc).map(({ id, content }) => [id, (content as { text: string }[]).map(({ text }) => text).join("")]);
    }

    function typeInto(doc: Y.Doc, blockIndex: number, index: number, text: string) {
      const blockGroup = doc.getXmlFragment(DOCUMENT_FRAGMENT).firstChild as Y.XmlElement;
      const paragraph = (blockGroup.get(blockIndex) as Y.XmlElement).firstChild as Y.XmlElement;
      (paragraph.firstChild as Y.XmlText).insert(index, text);
    }

    it("merges an edit with concurrent typing in the same block", () => {
      const live = documentWith([{ id: "a", type: "paragraph", content: "Hello world" }]);
      const base = Y.encodeStateAsUpdate(live);
      typeInto(live, 0, 5, ", dear");

      const { update } = editOnto(base, normalizeBlocks([{ id: "a", type: "paragraph", content: "Hello world!" }]));
      Y.applyUpdate(live, update);

      expect(contents(live)).toEqual([["a", "Hello, dear world!"]]);
    });

    it("keeps blocks inserted concurrently by others", () => {
      const live = documentWith([{ id: "a", type: "paragraph", content: "A" }, { id: "b", type: "paragraph", content: "B" }]);
      const base = Y.encodeStateAsUpdate(live);
      const target = readBlocks(live);
      writeBlocks(live, normalizeBlocks([...target, { id: "user", type: "paragraph", content: "By user" }]));

      const { update } = editOnto(base, normalizeBlocks([{ id: "ai", type: "paragraph", content: "By AI" }, ...target]));
      Y.applyUpdate(live, update);

      expect(contents(live)).toEqual([["ai", "By AI"], ["a", "A"], ["b", "B"], ["user", "By user"]]);
    });

    it("produces only the new changes when editing on top of its own edited state", () => {
      const live = documentWith([{ id: "a", type: "paragraph", content: "Hello" }]);
      const first = editOnto(Y.encodeStateAsUpdate(live), normalizeBlocks([{ id: "a", type: "paragraph", content: "Hello!" }]));
      Y.applyUpdate(live, first.update);

      const repeated = editOnto(first.editedState, normalizeBlocks([{ id: "a", type: "paragraph", content: "Hello!" }]));
      Y.applyUpdate(live, repeated.update);

      expect(contents(live)).toEqual([["a", "Hello!"]]);
    });
  });
});
